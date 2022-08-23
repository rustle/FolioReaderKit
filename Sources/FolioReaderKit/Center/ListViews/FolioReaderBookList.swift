//
//  FolioReaderBookList.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 15/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import AEXML

/// Table Of Contents delegate
@objc protocol FolioReaderBookListDelegate: AnyObject {
    /**
     Notifies when the user selected some item on menu.
     */
    func bookList(_ bookList: FolioReaderBookList, didSelectRowAtIndexPath indexPath: IndexPath, withTocReference reference: FRTocReference)

    /**
     Notifies when book list did totally dismissed.
     */
    func bookList(didDismissedBookList bookList: FolioReaderBookList)
}

class FolioReaderBookList: UICollectionViewController {
    weak var delegate: FolioReaderBookListDelegate?
    fileprivate var tocItems = [FRTocReference]()
    fileprivate var tocPositions = [FRTocReference: FolioReaderReadPosition]()
    fileprivate var book: FRBook
    fileprivate var readerConfig: FolioReaderConfig
    fileprivate var folioReader: FolioReader
    fileprivate var highlightResourceIds = Set<String>()
    fileprivate var layout = UICollectionViewFlowLayout()
    
    init(folioReader: FolioReader, readerConfig: FolioReaderConfig, book: FRBook, delegate: FolioReaderBookListDelegate?) {
        self.readerConfig = readerConfig
        self.folioReader = folioReader
        self.delegate = delegate
        self.book = book
        
        layout.itemSize = .init(width: 300, height: 400)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 16
        layout.scrollDirection = .vertical
        
        super.init(collectionViewLayout: layout)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init with coder not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        self.collectionView.register(FolioReaderBookListCell.self, forCellWithReuseIdentifier: kReuseCellIdentifier)
//        self.collectionView.separatorInset = UIEdgeInsets.zero
        //self.tableView.backgroundColor = self.folioReader.isNight(self.readerConfig.nightModeMenuBackground, self.readerConfig.menuBackgroundColor)
        self.collectionView.backgroundColor = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]
//        self.collectionView.separatorColor = self.folioReader.isNight(self.readerConfig.nightModeSeparatorColor, self.readerConfig.menuSeparatorColor)

//        self.collectionView.rowHeight = UITableView.automaticDimension
//        self.collectionView.estimatedRowHeight = 50

        // Create TOC list
        guard self.folioReader.structuralStyle == .bundle else { return }
        
        self.tocItems = self.book.bundleRootTableOfContents
      
        self.tocItems.forEach {
            let bookTocIndexPathRow = self.book.findPageByResource($0)
            if let bookId = self.folioReader.readerContainer?.book.name?.deletingPathExtension {
                let bookTocPageNumber = bookTocIndexPathRow + 1
                if let readPosition = self.folioReader.delegate?.folioReaderReadPositionProvider?(self.folioReader).folioReaderReadPosition(self.folioReader, bookId: bookId, by: bookTocPageNumber) {
                    self.tocPositions[$0] = readPosition
                }
            }
        }
        // Jump to the current book
        DispatchQueue.main.async {
            guard let index = self.tocItems.firstIndex(where: { self.highlightResourceIds.contains($0.resource?.id ?? "___NIL___") }) else { return }
            let indexPath = IndexPath(row: index, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        highlightResourceIds.removeAll()
        
        guard let currentPage = self.folioReader.readerCenter?.currentPage else { return }
        
        highlightResourceIds.formUnion(currentPage.getChapterTocReferences(for: .zero, by: .zero).compactMap { $0.resource?.id })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Jump to the current book
        DispatchQueue.main.async {
            guard let currentPageNumber = self.folioReader.readerCenter?.currentPageNumber,
                  let reference = self.book.spine.spineReferences[safe: currentPageNumber - 1],
                  let index = self.tocItems.firstIndex(where: { $0.resource == reference.resource })
            else { return }
            
            let indexPath = IndexPath(row: index, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let minWidth = 200.0
        
        let itemCount = floor(self.collectionView.frame.size.width / minWidth)
        let itemWidth = floor((self.collectionView.frame.size.width - layout.minimumInteritemSpacing*(itemCount-1)) / itemCount)
        let itemHeight = itemWidth * 1.333 + 80
        layout.itemSize = .init(width: itemWidth, height: itemHeight)
        
//        layout.invalidateLayout()
    }

    // MARK: - collection view data source
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tocItems.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kReuseCellIdentifier, for: indexPath) as! FolioReaderBookListCell

        cell.setup(withConfiguration: self.readerConfig)
        let tocReference = tocItems[indexPath.row]

        cell.titleLabel.text = Array.init(repeating: " ", count: (tocReference.level ?? 0) * 2).joined() + tocReference.title.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add audio duration for Media Ovelay
        if let resource = tocReference.resource {
            if let mediaOverlay = resource.mediaOverlay {
                let duration = self.book.duration(for: "#"+mediaOverlay)

                if let durationFormatted = (duration != nil ? duration : "")?.clockTimeToMinutesString() {
                    cell.titleLabel.text = (cell.titleLabel.text ?? "") + (duration != nil ? (" - " + durationFormatted) : "")
                }
            }
        }

        // Mark current reading book
        cell.titleLabel.textColor = highlightResourceIds.contains(tocReference.resource?.id ?? "___NIL___") ? self.readerConfig.menuTextColorSelected : self.readerConfig.menuTextColor
        
        cell.positionLabel.textColor = highlightResourceIds.contains(tocReference.resource?.id ?? "___NIL___") ? self.readerConfig.menuTextColorSelected : self.readerConfig.menuTextColor
        cell.positionLabel.font = UIFont(name: "Avenir-Light", size: 15.0)

        cell.percentageLabel.textColor = highlightResourceIds.contains(tocReference.resource?.id ?? "___NIL___") ? self.readerConfig.menuTextColorSelected : self.readerConfig.menuTextColor
        cell.percentageLabel.font = UIFont(name: "Avenir-Light", size: 11.0)
        
        if let position = tocPositions[tocReference] {
            cell.positionLabel.text = position.chapterName
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.minimumFractionDigits = 1
            formatter.maximumFractionDigits = 1
            cell.percentageLabel.text = (formatter.string(from: NSNumber(value: position.chapterProgress / 100.0)) ?? "0.0%") + " / " + (formatter.string(from: NSNumber(value: position.bookProgress / 100.0)) ?? "0.0%")
        } else {
            cell.positionLabel.text = "Not Started"
            cell.percentageLabel.text = ""
        }
        
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.contentView.backgroundColor = UIColor.clear
        cell.backgroundColor = UIColor.clear
        
        cell.coverImage.image = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let book = self.folioReader.readerContainer?.book,
                  let bookId = self.folioReader.readerConfig?.identifier,
                  let archive = book.threadEpubArchive,
                  let resource = tocReference.resource,
                  let tocPage = resource.spineIndices.first,
                  let opfURL = URL(string: book.opfResource.href)
            else { return }
            
            var imgNodes = [AEXMLElement]()
            var coverURL = opfURL
            
            for page in (max(0,tocPage-2) ... tocPage).reversed() {
                if let resource = book.spine.spineReferences[safe: page]?.resource,
                   let entryURL = URL(string: resource.href, relativeTo: opfURL),
                   let entry = archive[entryURL.absoluteString.trimmingCharacters(in: ["/"])] {
                    var entryData = Data()
                    let _ = try? archive.extract(entry, consumer: { data in
                        entryData.append(data)
                    })
                    if let xmlDoc = try? AEXMLDocument(xml: entryData) {
                        imgNodes = xmlDoc.allDescendants { $0.name == "img" || $0.name == "IMG" || $0.name == "image" || $0.name == "IMAGE" }
                    }
                    if imgNodes.isEmpty == false {
                        coverURL = entryURL
                        break
                    }
                }
            }
            
            guard let imgSrc = imgNodes.first?.attributes["src"] ?? imgNodes.first?.attributes["xlink:href"] ?? book.coverImage?.href,
                  let imgURL = URL(string: imgSrc, relativeTo: URL(string: coverURL.absoluteString.trimmingCharacters(in: ["/"]))),
                  let imgEntry = archive[imgURL.absoluteString.trimmingCharacters(in: ["/"])]
            else { return }
            
            let tempFile = URL(
                fileURLWithPath: imgEntry.path,
                relativeTo: FileManager.default.temporaryDirectory.appendingPathComponent(bookId, isDirectory: true))
            let tempDir = tempFile.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
            
            if FileManager.default.fileExists(atPath: tempFile.path) == false {
                let _ = try? archive.extract(imgEntry, to: tempFile)
            }
            if let image = UIImage(contentsOfFile: tempFile.path) {
                DispatchQueue.main.async {
                    cell.coverImage.image = image
                    cell.coverImage.contentMode = .scaleAspectFit
                }
            }
        }
        
        return cell
    }

    // MARK: - Table view delegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tocReference = tocItems[(indexPath as NSIndexPath).row]
        if let position = tocPositions[tocReference] {
            self.folioReader.readerCenter?.currentWebViewScrollPositions[position.pageNumber - 1] = position
        }
        delegate?.bookList(self, didSelectRowAtIndexPath: indexPath, withTocReference: tocReference)
        
        collectionView.deselectItem(at: indexPath, animated: true)
        dismiss { 
            self.delegate?.bookList(didDismissedBookList: self)
        }
    }
}

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
        self.collectionView.backgroundColor = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]

        // Create TOC list
        guard self.folioReader.structuralStyle == .bundle else { return }
        let rootTocLevel = self.folioReader.structuralTrackingTocLevel.rawValue
        
        self.tocItems = self.book.flatTableOfContents.filter {
            ($0.level ?? 0) < rootTocLevel
        }
        
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
        
        if self.folioReader.currentNavigationMenuBookListSyle == 0 {    //grid
            let minWidth = 200.0
            
            let itemCount = floor(self.collectionView.frame.size.width / minWidth)
            let itemWidth = floor((self.collectionView.frame.size.width - layout.minimumInteritemSpacing*(itemCount-1)) / itemCount)
            let itemHeight = itemWidth * 1.333 + 80
            layout.itemSize = .init(width: itemWidth, height: itemHeight)
            layout.minimumLineSpacing = 16
        } else {    //list
            let itemWidth = self.collectionView.frame.size.width
            let itemHeight = 64.0
            layout.itemSize = .init(width: itemWidth, height: itemHeight)
            layout.minimumLineSpacing = 0
        }
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
        
        cell.coverImage.image = nil
        
        if tocReference.level != self.folioReader.structuralTrackingTocLevel.rawValue - 1 {
            cell.positionLabel.isHidden = true
            cell.percentageLabel.isHidden = true
            cell.contentView.backgroundColor = UIColor(white: 0.7, alpha: 0.1)
            cell.backgroundColor = UIColor(white: 0.7, alpha: 0.1)
        } else {
            cell.positionLabel.isHidden = false
            cell.percentageLabel.isHidden = false
            cell.contentView.backgroundColor = .clear
            cell.backgroundColor = UIColor.clear
        }
        
        guard self.folioReader.currentNavigationMenuBookListSyle == 0 else { return cell }
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let book = self.folioReader.readerContainer?.book,
                  let bookId = self.folioReader.readerConfig?.identifier,
                  let archive = book.threadEpubArchive,
                  let resource = tocReference.resource,
                  let tocPage = resource.spineIndices.first
            else { return }
            
            let opfURL = URL(fileURLWithPath: book.opfResource.href, isDirectory: false)
            var imgNodes = [AEXMLElement]()
            var coverURL = opfURL
            
            for page in (max(0,tocPage-1) ... tocPage).reversed() {
                let resource = book.spine.spineReferences[page].resource
                let entryURL = URL(fileURLWithPath: resource.href, isDirectory: false, relativeTo: opfURL)
                guard let entry = archive[entryURL.path.trimmingCharacters(in: ["/"])] else { continue }
                
                var entryData = Data()
                let _ = try? archive.extract(entry, consumer: { data in
                    entryData.append(data)
                })
                guard let xmlDoc = try? AEXMLDocument(xml: entryData) else { continue }
                
                imgNodes = xmlDoc.allDescendants { $0.name == "img" || $0.name == "IMG" || $0.name == "image" || $0.name == "IMAGE" }
                
                if imgNodes.isEmpty == false {
                    coverURL = entryURL
                    break
                }
            }
            
            guard let imgSrc = imgNodes.first?.attributes["src"] ?? imgNodes.first?.attributes["xlink:href"] ?? book.coverImage?.href,
                  let imgEntry = archive[URL(fileURLWithPath: imgSrc, relativeTo: coverURL).path.trimmingCharacters(in: ["/"])]
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
                }
            }
        }
        
        return cell
    }

    // MARK: - Table view delegate

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let rootTocLevel = self.folioReader.structuralTrackingTocLevel.rawValue
        return tocItems[indexPath.row].level == rootTocLevel - 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tocReference = tocItems[indexPath.row]
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

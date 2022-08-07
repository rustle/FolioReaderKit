//
//  FolioReaderBookList.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 15/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

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

class FolioReaderBookList: UITableViewController {

    weak var delegate: FolioReaderBookListDelegate?
    fileprivate var tocItems = [FRTocReference]()
    fileprivate var tocPositions = [FRTocReference: FolioReaderReadPosition]()
    fileprivate var book: FRBook
    fileprivate var readerConfig: FolioReaderConfig
    fileprivate var folioReader: FolioReader
    fileprivate var highlightResourceIds = Set<String>()

    init(folioReader: FolioReader, readerConfig: FolioReaderConfig, book: FRBook, delegate: FolioReaderBookListDelegate?) {
        self.readerConfig = readerConfig
        self.folioReader = folioReader
        self.delegate = delegate
        self.book = book

        super.init(style: UITableView.Style.plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init with coder not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        self.tableView.register(FolioReaderBookListCell.self, forCellReuseIdentifier: kReuseCellIdentifier)
        self.tableView.separatorInset = UIEdgeInsets.zero
        //self.tableView.backgroundColor = self.folioReader.isNight(self.readerConfig.nightModeMenuBackground, self.readerConfig.menuBackgroundColor)
        self.tableView.backgroundColor = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]
        self.tableView.separatorColor = self.folioReader.isNight(self.readerConfig.nightModeSeparatorColor, self.readerConfig.menuSeparatorColor)

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 50

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
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        highlightResourceIds.removeAll()
        
        guard let currentPage = self.folioReader.readerCenter?.currentPage else { return }
        
        highlightResourceIds.formUnion(currentPage.getChapterTocReferences(for: .zero, by: .zero).compactMap { $0.resource?.id })
//        currentPage.getChapterNames(for: .zero, by: currentPage.webViewFrame().size()).map { $0. }
        
        
        
//        while( tocRef != nil ) {
//            if let id = tocRef?.resource?.id {
//                highlightResourceIds.insert(id)
//            }
//            tocRef = tocRef?.parent
//        }
        
//        while( pageNumber > 0 ) {
//            guard let reference = self.book.spine.spineReferences[safe: pageNumber - 1] else { return }
//            if let tocReferences = self.book.resourceTocMap[reference.resource] {
//                tocReferences.forEach {
//                    if let id = $0.resource?.id {
//                        highlightResourceIds.insert(id)
//                    }
//                    var parent = $0.parent
//                    while( parent != nil ) {
//                        if let id = parent?.resource?.id {
//                            highlightResourceIds.insert(id)
//                        }
//                        parent = parent?.parent
//                    }
//                }
//                break
//            } else {
//                pageNumber -= 1
//            }
//        }
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
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tocItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: kReuseCellIdentifier)
        let cell = tableView.dequeueReusableCell(withIdentifier: kReuseCellIdentifier, for: indexPath) as! FolioReaderBookListCell

        cell.setup(withConfiguration: self.readerConfig)
        let tocReference = tocItems[indexPath.row]

        cell.indexLabel.text = Array.init(repeating: " ", count: (tocReference.level ?? 0) * 2).joined() + tocReference.title.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add audio duration for Media Ovelay
        if let resource = tocReference.resource {
            if let mediaOverlay = resource.mediaOverlay {
                let duration = self.book.duration(for: "#"+mediaOverlay)

                if let durationFormatted = (duration != nil ? duration : "")?.clockTimeToMinutesString() {
                    cell.indexLabel.text = (cell.indexLabel.text ?? "") + (duration != nil ? (" - " + durationFormatted) : "")
                }
            }
        }

        // Mark current reading book
        cell.indexLabel.textColor = highlightResourceIds.contains(tocReference.resource?.id ?? "___NIL___") ? self.readerConfig.menuTextColorSelected : self.readerConfig.menuTextColor
        cell.indexLabel.font = UIFont(name: "Avenir-Light", size: 17.0)
        
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
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tocReference = tocItems[(indexPath as NSIndexPath).row]
        if let position = tocPositions[tocReference] {
            self.folioReader.readerCenter?.currentWebViewScrollPositions[position.pageNumber - 1] = position
        }
        delegate?.bookList(self, didSelectRowAtIndexPath: indexPath, withTocReference: tocReference)
        
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss { 
            self.delegate?.bookList(didDismissedBookList: self)
        }
    }
}

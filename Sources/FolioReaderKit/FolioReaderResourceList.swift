//
//  FolioReaderResourceList.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 15/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

/// Table Of Contents delegate
@objc protocol FolioReaderResourceListDelegate: AnyObject {
    /**
     Notifies when the user selected some item on menu.
     */
    func resourceList(_ resourceList: FolioReaderResourceList, didSelectRowAtIndexPath indexPath: IndexPath)

    /**
     Notifies when resource list did totally dismissed.
     */
    func resourceList(didDismissedResourceList resourceList: FolioReaderResourceList)
}

class FolioReaderResourceList: UITableViewController {

    weak var delegate: FolioReaderResourceListDelegate?
    fileprivate var tocItems = [FRTocReference]()
    fileprivate var book: FRBook
    fileprivate var readerConfig: FolioReaderConfig
    fileprivate var folioReader: FolioReader

    init(folioReader: FolioReader, readerConfig: FolioReaderConfig, book: FRBook, delegate: FolioReaderResourceListDelegate?) {
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
        self.tableView.register(FolioReaderResourceListCell.self, forCellReuseIdentifier: kReuseCellIdentifier)
        self.tableView.separatorInset = UIEdgeInsets.zero
        //self.tableView.backgroundColor = self.folioReader.isNight(self.readerConfig.nightModeMenuBackground, self.readerConfig.menuBackgroundColor)
        self.tableView.backgroundColor = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]
        self.tableView.separatorColor = self.folioReader.isNight(self.readerConfig.nightModeSeparatorColor, self.readerConfig.menuSeparatorColor)

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 50

        // Create TOC list
        self.tocItems = self.book.flatTableOfContents
        
        // Jump to the current resource
        DispatchQueue.main.async {
            if let currentPageNumber = self.folioReader.readerCenter?.currentPageNumber {
                  let indexPath = IndexPath(row: currentPageNumber - 1, section: 0)
                  self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Jump to the current resource
        DispatchQueue.main.async {
            if let currentPageNumber = self.folioReader.readerCenter?.currentPageNumber {
                  let indexPath = IndexPath(row: currentPageNumber - 1, section: 0)
                  self.tableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return book.spine.spineReferences.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kReuseCellIdentifier, for: indexPath) as! FolioReaderResourceListCell

        cell.setup(withConfiguration: self.readerConfig)
        let spineReference = book.spine.spineReferences[indexPath.row]
        let isSection = false

        cell.indexLabel.text = spineReference.resource.href
        cell.indexSize.text = ByteCountFormatter.string(fromByteCount: Int64(spineReference.resource.size ?? 0), countStyle: .file)

        // Add audio duration for Media Ovelay
        if let mediaOverlay = spineReference.resource.mediaOverlay {
            let duration = self.book.duration(for: "#"+mediaOverlay)
            
            if let durationFormatted = (duration != nil ? duration : "")?.clockTimeToMinutesString() {
                cell.indexLabel.text = (cell.indexLabel.text ?? "") + (duration != nil ? (" - " + durationFormatted) : "")
            }
        }

        // Mark current reading resource
        cell.indexLabel.textColor = (indexPath.row + 1 == self.folioReader.readerCenter?.currentPageNumber ? self.readerConfig.menuTextColorSelected : self.readerConfig.menuTextColor)
        cell.indexLabel.font = UIFont(name: "Avenir-Light", size: 15.0)

        cell.indexSize.textColor = (indexPath.row + 1 == self.folioReader.readerCenter?.currentPageNumber ? self.readerConfig.menuTextColorSelected : self.readerConfig.menuTextColor)
        cell.indexSize.font = UIFont(name: "Avenir-Light", size: 13.0)

        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.contentView.backgroundColor = isSection ? UIColor(white: 0.7, alpha: 0.1) : UIColor.clear
        cell.backgroundColor = UIColor.clear
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.resourceList(self, didSelectRowAtIndexPath: indexPath)
        
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss { 
            self.delegate?.resourceList(didDismissedResourceList: self)
        }
    }
}

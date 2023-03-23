//
//  PageDelegation.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/14.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import UIKit

extension FolioReaderCenter: FolioReaderPageDelegate {

    public func pageDidLoad(_ page: FolioReaderPage) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

//        let indexPath = getCurrentIndexPath(navigating: to)
//        guard indexPath.row + 1 == page.pageNumber else { return }  //guard against cancelled page transition
        
//        updateCurrentPage(page)
        
        //if scrolling to a new book (bundle style), jump to its last read position
        if self.folioReader.structuralStyle == .bundle,
           page.pageNumber > 1,
           self.pageScrollDirection == page.byWritingMode(.left, .right),
           let bundleRootTocIndex = page.getBundleRootTocIndex(),
           let bundleRootToc = self.book.bundleRootTableOfContents[safe: bundleRootTocIndex],
           let bundleRootResourceSpineIndices = bundleRootToc.resource?.spineIndices,
           bundleRootResourceSpineIndices.contains(page.pageNumber - 1),
           let bookId = self.book.name?.deletingPathExtension,
           let readPosition = self.folioReader.delegate?.folioReaderReadPositionProvider(self.folioReader).folioReaderReadPosition(self.folioReader, bookId: bookId, by: page.pageNumber),
           readPosition.pageNumber != page.pageNumber {
            
            folioLogger("NEW_BOOK_NAV readPosition=\(readPosition.pageNumber)")
            currentWebViewScrollPositions[readPosition.pageNumber - 1] = readPosition
            let indexPath = IndexPath(row: readPosition.pageNumber - 1, section: 0)
            changePageWith(indexPath: indexPath, animated: true) {
                self.currentPage?.updatePageInfo {
                    self.currentPage?.updatePageOffsetRate()
                }
            }
            return
        }
        
        guard let webView = page.webView else { return }
        
        // UGLYFIX: to make share menu item appear on first attempt
        webView.scrollView.subviews.first?.becomeFirstResponder()
        page.becomeFirstResponder()
        webView.createMenu(onHighlight: false)
        
        // set scroll slider frame based on page writing mode
        updateSubviewFrames()
        
        if self.isScrolling == false {
            if self.folioReader.needsRTLChange {
                page.scrollPageToBottom()
            } else {
                page.scrollPageToOffset(.zero, animated: false, retry: 0)
            }
        }
        
        // Go to fragment if needed
        if let fragmentID = tempFragment,
           fragmentID.isEmpty == false,
           page.pageNumber == currentPage?.pageNumber {
            delay(0.2) {
                page.handleAnchor(fragmentID, offsetInWindow: 0, avoidBeginningAnchors: true, animated: true) {
                    self.tempFragment = nil
                    delay(0.5) {
                        page.getWebViewScrollPosition { position in
                            self.currentWebViewScrollPositions[page.pageNumber - 1] = position
                        }
                    }
                }
            }
        } else if let position = self.folioReader.readerCenter?.currentWebViewScrollPositions[page.pageNumber - 1],
                  position.cfi.starts(with: "epubcfi("),
                  (page.pageNumber > 1 ? position.cfi != "epubcfi(/2/2)" : true),
                  position.cfi != "epubcfi(/\(page.pageNumber * 2)/2)" {
            self.readerContainer?.centerViewController?.pageIndicatorView?.infoLabel.text = position.cfi
            delay(0.2) {
                page.handleAnchor(position.cfi, offsetInWindow: 0, avoidBeginningAnchors: true, animated: true) {
                    delay(0.5) {
                        page.getWebViewScrollPosition { position in
                            self.currentWebViewScrollPositions[page.pageNumber - 1] = position
                        }
                    }
                }
            }
        } else if let position = self.folioReader.readerCenter?.currentWebViewScrollPositions[page.pageNumber - 1] {
            self.readerContainer?.centerViewController?.pageIndicatorView?.infoLabel.text = position.cfi
            folioLogger("bridgeFinished isFirstLoad pageNumber=\(page.pageNumber)")
            
            page.scrollWebViewByPosition(
                pageOffset: position.pageOffset.forDirection(withConfiguration: self.readerConfig),
                pageProgress: position.chapterProgress
            )
        } else {
            self.readerContainer?.centerViewController?.pageIndicatorView?.infoLabel.text = "Missing Position"
        }

        // Pass the event to the centers `pageDelegate`
        pageDelegate?.pageDidLoad?(page)
    }
    
    public func pageWillLoad(_ page: FolioReaderPage) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        // Pass the event to the centers `pageDelegate`
        pageDelegate?.pageWillLoad?(page)
    }
    
    public func pageTap(_ recognizer: UITapGestureRecognizer) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        // Pass the event to the centers `pageDelegate`
        pageDelegate?.pageTap?(recognizer)
    }
    
}

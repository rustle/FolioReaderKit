//
//  PageDelegation.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/14.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import Foundation

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
           let readPosition = self.folioReader.delegate?.folioReaderReadPositionProvider?(self.folioReader).folioReaderReadPosition(self.folioReader, bookId: bookId, by: page.pageNumber),
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
        
//        webView.js("""
//            getElementOffsetByCFI()
//        """) { offset in
//            folioLogger("getElementOffsetByCFI offset=\(String(describing: offset))")
//        }
        // Go to fragment if needed
        if let fragmentID = tempFragment, let currentPage = currentPage , fragmentID != "" {
            currentPage.handleAnchor(fragmentID, offsetInWindow: 0, avoidBeginningAnchors: true, animated: true)
            tempFragment = nil
        } else
            // if readerCenter.isFirstLoad {
            if let position = self.folioReader.readerCenter?.currentWebViewScrollPositions[page.pageNumber - 1] {
                folioLogger("bridgeFinished isFirstLoad pageNumber=\(page.pageNumber)")
                
                // if self.readerConfig.loadSavedPositionForCurrentBook,
                // let position = self.folioReader.savedPositionForCurrentBook {
                //      if self.pageNumber == position["pageNumber"] as? Int {
                var pageOffset = position.pageOffset.forDirection(withConfiguration: self.readerConfig)
                
                let fileSize = self.book.spine.spineReferences[safe: page.pageNumber-1]?.resource.size ?? 102400
                let delaySec = 0.2 + Double(fileSize / 51200) * (self.readerConfig.scrollDirection == .horitonzalWithPagedContent ? 0.25 : 0.1)
                delay(delaySec) {
                    let chapterProgress = position.chapterProgress
                    
                    let contentSize = webView.scrollView.contentSize
                    let webViewFrameSize = webView.frame.size
                    
                    var pageOffsetByProgress = page.byWritingMode(
                        contentSize.forDirection(withConfiguration: self.readerConfig) * chapterProgress,
                        contentSize.width * (100 - chapterProgress - webViewFrameSize.width / contentSize.width * 100)) / 100
                    if pageOffset < pageOffsetByProgress * 0.95 || pageOffset > pageOffsetByProgress * 1.05 {
                        if page.byWritingMode(self.readerConfig.scrollDirection == .horitonzalWithPagedContent, true) {
                            let pageInPage = page.byWritingMode(
                                floor( pageOffsetByProgress / webViewFrameSize.width ),
                                max(floor( (contentSize.width - pageOffsetByProgress) / webViewFrameSize.width), 1)
                            )
                            pageOffsetByProgress = page.byWritingMode(pageInPage * webViewFrameSize.width, contentSize.width - pageInPage * webViewFrameSize.width)
                        }
                        pageOffset = pageOffsetByProgress - page.byWritingMode(
                            self.readerConfig.isDirection(self.pageHeight / 2, self.pageWidth / 2, self.pageHeight / 2),
                            webViewFrameSize.width / 2
                        )
                    }
                    if pageOffset < 0 {
                        pageOffset = 0
                    }
                    page.pageOffsetRate = pageOffset / page.byWritingMode(contentSize.forDirection(withConfiguration: self.readerConfig), contentSize.width)
                    page.scrollWebViewByPageOffsetRate(animated: false) {
                        delay(2.0) {
                            page.getWebViewScrollPosition { position in
                                self.currentWebViewScrollPositions[page.pageNumber - 1] = position
                            }
                        }
                    }
                }
                //      readerCenter.isFirstLoad = false
                // } else if position["pageNumber"] as? Int == 0 {
                //      readerCenter.isFirstLoad = false
                //  }
                //}
            } else if self.isScrolling == false {
                if self.folioReader.needsRTLChange {
                    page.scrollPageToBottom()
                } else {
                    page.scrollPageToOffset(.zero, animated: false, retry: 0)
                }
            }
        //if let offsetPoint = self.currentWebViewScrollPositions[page.pageNumber - 1] {
//            page.setScrollViewContentOffset(offsetPoint, animated: false)
            
//        }
        
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

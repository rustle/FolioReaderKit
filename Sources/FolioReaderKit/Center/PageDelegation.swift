//
//  PageDelegation.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/14.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import Foundation

extension FolioReaderCenter: FolioReaderPageDelegate {

    public func pageDidLoad(_ page: FolioReaderPage, navigating to: IndexPath?) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let indexPath = getCurrentIndexPath(navigating: to)
        guard indexPath.row + 1 == page.pageNumber else { return }  //guard against cancelled page transition
        
        if self.readerConfig.loadSavedPositionForCurrentBook, let position = folioReader.savedPositionForCurrentBook {
            let pageNumber = position["pageNumber"] as? Int

            if isFirstLoad {
                updateCurrentPage(page)
                isFirstLoad = false

                if self.currentPageNumber == pageNumber {
                    var pageOffset = self.readerConfig.isDirection(position["pageOffsetY"], position["pageOffsetX"], position["pageOffsetY"]) as? CGFloat ?? 0
                    
                    delay(0.3) {
                        if let chapterProgress = position["chapterProgress"] as? CGFloat {
                            var pageOffsetByProgress = (page.webView?.scrollView.contentSize.forDirection(withConfiguration: self.readerConfig) ?? 0) * chapterProgress / 100
                            if (self.readerConfig.scrollDirection == .horizontal && self.pageWidth != 0) {
                                let page = floor(pageOffsetByProgress / self.pageWidth)
                                pageOffsetByProgress = page * self.pageWidth
                            }
                            if pageOffset < pageOffsetByProgress * 0.95 || pageOffset > pageOffsetByProgress * 1.05 {
                                pageOffset = pageOffsetByProgress - self.pageHeight / 2
                            }
                        }
                        if pageOffset > 0 {
                            page.scrollPageToOffset(pageOffset, animated: false)
                        }
                    }
                }
            } else if (self.isScrolling == false && folioReader.needsRTLChange == true) {
                page.scrollPageToBottom()
            }
        } else if isFirstLoad {
            updateCurrentPage(page)
            isFirstLoad = false
        }

        updateCurrentPage(page)
        page.webView?.isHidden = false
        
        // UGLYFIX: to make share menu item appear on first attempt
        page.webView?.scrollView.subviews.first?.becomeFirstResponder()
        page.becomeFirstResponder()
        page.webView?.createMenu(onHighlight: false)
        
        // Go to fragment if needed
        if let fragmentID = tempFragment, let currentPage = currentPage , fragmentID != "" {
            currentPage.handleAnchor(fragmentID, offsetInWindow: 0, avoidBeginningAnchors: true, animated: true)
            tempFragment = nil
        } else if let offsetPoint = self.currentWebViewScrollPositions[page.pageNumber - 1] {
            page.webView?.scrollView.setContentOffset(offsetPoint, animated: false)
        }
        
        // Pass the event to the centers `pageDelegate`
        pageDelegate?.pageDidLoad?(page, navigating: to)
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

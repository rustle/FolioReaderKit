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
        
        updateCurrentPage(page)
        
        // UGLYFIX: to make share menu item appear on first attempt
        page.webView?.scrollView.subviews.first?.becomeFirstResponder()
        page.becomeFirstResponder()
        page.webView?.createMenu(onHighlight: false)
        
        // Go to fragment if needed
        if let fragmentID = tempFragment, let currentPage = currentPage , fragmentID != "" {
            currentPage.handleAnchor(fragmentID, offsetInWindow: 0, avoidBeginningAnchors: true, animated: true)
            tempFragment = nil
        } else if let offsetPoint = self.currentWebViewScrollPositions[page.pageNumber - 1] {
            page.setScrollViewContentOffset(offsetPoint, animated: false)
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

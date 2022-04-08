//
//  CenterDelegate.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/14.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import Foundation

/// Protocol which is used from `FolioReaderCenter`s.
@objc public protocol FolioReaderCenterDelegate: AnyObject {

    /// Notifies that a page appeared. This is triggered when a page is chosen and displayed.
    ///
    /// - Parameter page: The appeared page
    @objc optional func pageDidAppear(_ page: FolioReaderPage)

    /// Passes and returns the HTML content as `String`. Implement this method if you want to modify the HTML content of a `FolioReaderPage`.
    ///
    /// - Parameters:
    ///   - page: The `FolioReaderPage`.
    ///   - htmlContent: The current HTML content as `String`.
    /// - Returns: The adjusted HTML content as `String`. This is the content which will be loaded into the given `FolioReaderPage`.
    @objc func htmlContentForPage(_ page: FolioReaderPage, htmlContent: String) -> String
    
    /// Notifies that a page changed. This is triggered when collection view cell is changed.
    ///
    /// - Parameter pageNumber: The appeared page item
    @objc optional func pageItemChanged(_ pageNumber: Int)

}

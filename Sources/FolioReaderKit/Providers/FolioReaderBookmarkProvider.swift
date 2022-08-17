//
//  FolioReaderBookmarkProvider.swift
//  AEXML
//
//  Created by 京太郎 on 2021/9/23.
//

import Foundation

@objc public protocol FolioReaderBookmarkProvider: AnyObject {

    /// Save a Bookmark with completion block
    ///
    @objc func folioReaderBookmark(_ folioReader: FolioReader, added bookmark: FolioReaderBookmark, completion: Completion?)
    
    /// Remove a Bookmark by pos(cfi)
    ///
    @objc func folioReaderBookmark(_ folioReader: FolioReader, removed bookmarkPos: String)
    
    /// Update a Bookmark Title by pos
    ///
    @objc func folioReaderBookmark(_ folioReader: FolioReader, updated bookmarkPos: String, title: String)
    
    /// Return a Bookmark by Title
    ///
    @objc func folioReaderBookmark(_ folioReader: FolioReader, getBy bookmarkTitle: String) -> FolioReaderBookmark?
    
    /// Return a list of Bookmarks with specified book and optionally page
    ///
    /// - Parameters:
    ///   - bookId: Book ID
    ///   - page: Page number
    /// - Returns: Return a list of Bookmarks
    @objc func folioReaderBookmark(_ folioReader: FolioReader, allByBookId bookId: String, andPage page: NSNumber?) -> [FolioReaderBookmark]
    
    /// Return all Bookmarks
    ///
    /// - Returns: Return all Bookmarks
    @objc func folioReaderBookmark(_ folioReader: FolioReader) -> [FolioReaderBookmark]
}

public class FolioReaderNaiveBookmarkProvider: FolioReaderBookmarkProvider {
    
    var bookmarks = [String:FolioReaderBookmark]()  //key: pos
    
    public init() {
        let bookmark = FolioReaderBookmark()
        bookmark.pos_type = "epubcfi"
        bookmark.pos = "epubcfi(/22/2/4/10/1:316)"
        bookmark.page = 11
        bookmark.bookId = ""
        bookmark.title = "Test Bookmark"
        bookmark.date = Date(timeIntervalSince1970: 1660614468.141)
        bookmarks[bookmark.pos!] = bookmark
        
    }
    public func folioReaderBookmark(_ folioReader: FolioReader, added bookmark: FolioReaderBookmark, completion: Completion?) {
        var error:NSError? = nil
        defer {
            completion?(error)
        }
        
        guard let pos = bookmark.pos else {
            error = FolioReaderBookmarkError.emptyError("") as NSError
            return
        }
        
        guard bookmarks[pos] == nil else {
            error = FolioReaderBookmarkError.duplicateError(bookmarks[pos]?.title ?? "Untitled Bookmark") as NSError
            return
        }
        
        bookmarks[pos] = bookmark
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader, removed bookmarkPos: String) {
        bookmarks.removeValue(forKey: bookmarkPos)
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader, updated bookmarkPos: String, title: String) {
        bookmarks[bookmarkPos]?.title = title
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader, getBy bookmarkTitle: String) -> FolioReaderBookmark? {
        return bookmarks.values.filter { $0.title == bookmarkTitle }.first
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader, allByBookId bookId: String, andPage page: NSNumber?) -> [FolioReaderBookmark] {
        return bookmarks.values.filter { return $0.page == (page?.intValue ?? $0.page) }
    }
    
    public func folioReaderBookmark(_ folioReader: FolioReader) -> [FolioReaderBookmark] {
        return bookmarks.values.map { $0 }
    }
    
}

//
//  Bookmark.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 11/08/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation

/// A Bookmark object
@objc open class FolioReaderBookmark: NSObject, Codable {
    open var bookId: String!
    
    open var date: Date!
    open var title: String!
    open var page: Int = 0
    open var pos_type: String?      //should be epubcfi
    open var pos: String?       //like epubcfi(/2/4/4/1:10)
}

public enum FolioReaderBookmarkError: Error {
    case emptyError(String)
    case duplicateError(String)
    case runtimeError(String)
}

extension FolioReaderBookmark: Comparable {
    public static func < (lhs: FolioReaderBookmark, rhs: FolioReaderBookmark) -> Bool {
        if lhs.page != rhs.page {
            return lhs.page < rhs.page
        }
        if let lStart = lhs.pos, let rStart = rhs.pos {
            let lSplit = lStart.split { $0 == "/" || $0 == ":" || $0 == "(" || $0 == ")" }
            let rSplit = rStart.split { $0 == "/" || $0 == ":" || $0 == "(" || $0 == ")" }
            for i in 0..<min(lSplit.count, rSplit.count) {
                let l = Int(lSplit[i]) ?? 0
                let r = Int(rSplit[i]) ?? 0
                if l != r {
                    return l < r
                }
            }
        }
        return lhs.title < rhs.title    //fallback
    }
    
}

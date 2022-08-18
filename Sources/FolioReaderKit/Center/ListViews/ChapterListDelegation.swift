//
//  ChapterListDelegation.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/14.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import Foundation

extension FolioReaderCenter: FolioReaderChapterListDelegate {
    
    func chapterList(_ chapterList: FolioReaderChapterList, didSelectRowAtIndexPath indexPath: IndexPath, withTocReference reference: FRTocReference) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let item = self.book.findPageByResource(reference)
        
        if item < totalPages {
            let indexPath = IndexPath(row: item, section: 0)
            changePageWith(indexPath: indexPath, animated: true, completion: { () -> Void in
                //self.updateCurrentPage(navigating: indexPath) //no need
                self.currentPage?.updatePageInfo {
                    self.currentPage?.updatePageOffsetRate()
                }
            })
            tempReference = reference
        } else {
            print("Failed to load book because the requested resource is missing.")
        }
    }
    
    func chapterList(didDismissedChapterList chapterList: FolioReaderChapterList) {
        // MARK: should not need here
        //updateCurrentPage()   
        
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        // Move to #fragment
        if let reference = tempReference {
            if let fragmentID = reference.fragmentID, let currentPage = currentPage , fragmentID != "" {
                currentPage.handleAnchor(reference.fragmentID!, offsetInWindow: self.navigationController?.toolbar.frame.height ?? 0, avoidBeginningAnchors: false, animated: true)
            }
            tempReference = nil
        }
    }
}

extension FolioReaderCenter: FolioReaderBookListDelegate {
    func bookList(_ bookList: FolioReaderBookList, didSelectRowAtIndexPath indexPath: IndexPath, withTocReference reference: FRTocReference) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

//        let item = findPageByResource(reference)
//
//        if item < totalPages {
//            let indexPath = IndexPath(row: item, section: 0)
//            changePageWith(indexPath: indexPath, animated: true, completion: { () -> Void in
//                //self.updateCurrentPage(navigating: indexPath) //no need
//                self.currentPage?.updatePageInfo {
//                    self.currentPage?.updatePageOffsetRate()
//                }
//            })
//            tempReference = reference
//        } else {
//            print("Failed to load book because the requested resource is missing.")
//        }
        
        func countTocChild(_ item: FRTocReference) -> [FRTocReference] {
            var tocItems = [FRTocReference]()

            item.children.forEach {
                tocItems.append($0)
                tocItems.append(contentsOf: countTocChild($0))
            }
            return tocItems
        }
        
        var tocItems = [FRTocReference]()
        tocItems.append(reference)
        tocItems.append(contentsOf: countTocChild(reference))
        
        let resourceSet = Set<String>(tocItems.compactMap { $0.resource?.href })
        
        var indexPath = indexPath
        if let position = self.currentWebViewScrollPositions.filter ({
            guard let href = self.book.spine.spineReferences[safe: $0.key]?.resource.href else { return false }
            return resourceSet.contains(href)
        }).max (by: { $0.key < $1.key }) {
            folioLogger("maxPosition=\(position)")
            indexPath = IndexPath(row: position.key, section: 0)
        } else {
            folioLogger("maxPosition=noPosition")
            let item = self.book.findPageByResource(reference)
            if item < totalPages {
                indexPath = IndexPath(row: item, section: 0)
            }
            tempReference = reference
        }
        
        changePageWith(indexPath: indexPath, animated: true, completion: { () -> Void in
            self.currentPage?.updatePageInfo {
                self.currentPage?.updatePageOffsetRate()
            }
        })
    }
    
    func bookList(didDismissedBookList bookList: FolioReaderBookList) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

//        // Move to #fragment
//        if let reference = tempReference {
//            if let fragmentID = reference.fragmentID, let currentPage = currentPage , fragmentID != "" {
//                currentPage.handleAnchor(reference.fragmentID!, offsetInWindow: self.navigationController?.toolbar.frame.height ?? 0, avoidBeginningAnchors: true, animated: true)
//            }
//            tempReference = nil
//        }
    }
}

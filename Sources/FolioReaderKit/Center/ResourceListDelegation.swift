//
//  ResourceListDelegation.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/14.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import Foundation

extension FolioReaderCenter: FolioReaderResourceListDelegate {
    
    func resourceList(_ resourceList: FolioReaderResourceList, didSelectRowAtIndexPath indexPath: IndexPath) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        if indexPath.row < totalPages {
            let indexPath = IndexPath(row: indexPath.row, section: 0)
            changePageWith(indexPath: indexPath, animated: true, completion: { () -> Void in
                //self.updateCurrentPage(navigating: indexPath) //no need
                self.currentPage?.updatePageInfo {
                    self.currentPage?.updatePageOffsetRate()
                }
            })
        } else {
            print("Failed to load book because the requested resource is missing.")
        }
    }
    
    func resourceList(didDismissedResourceList resourceList: FolioReaderResourceList) {
        // MARK: should not need here
        //updateCurrentPage()   
        
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        // Move to #fragment
        if let reference = tempReference {
            if let fragmentID = reference.fragmentID, let currentPage = currentPage , fragmentID != "" {
                currentPage.handleAnchor(reference.fragmentID!, offsetInWindow: self.navigationController?.toolbar.frame.height ?? 0, avoidBeginningAnchors: true, animated: true)
            }
            tempReference = nil
        }
    }
    
    
}


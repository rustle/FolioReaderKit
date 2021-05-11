//
//  File.swift
//  
//
//  Created by 京太郎 on 2021/4/6.
//

import Foundation

class MyFolioReaderCenterDelegate: FolioReaderCenterDelegate {
    
    @objc func htmlContentForPage(_ page: FolioReaderPage, htmlContent: String) -> String {
        
        // print(htmlContent)
        let regex = try! NSRegularExpression(pattern: "background=\"[^\"]+\"", options: .caseInsensitive)
        
        
        let modified = regex.stringByReplacingMatches(in: htmlContent, options: [], range: NSMakeRange(0, htmlContent.count), withTemplate: "").replacingOccurrences(of: "<body ", with: "<body style=\"text-align: justify !important; display: block !important; \" ")
        // print(modified)
        return modified
    }
}

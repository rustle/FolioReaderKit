//
//  Helpers.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/14.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import Foundation

func loadUserFonts() -> [String: CTFontDescriptor]? {
    guard let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    else { return nil }
    
    let fontsDirectory = documentDirectory.appendingPathComponent("Fonts",  isDirectory: true)
    guard FileManager.default.fileExists(atPath: fontsDirectory.path),
          let fontsEnumerator = FileManager.default.enumerator(atPath: fontsDirectory.path) else { return nil }
    
    var userFontDescriptors = [String: CTFontDescriptor]()
    while let file = fontsEnumerator.nextObject() as? String {
        print("FONTDIR \(file)")
        let fileURL = fontsDirectory.appendingPathComponent(file)
        
        if let ctFontDescriptorArray = CTFontManagerCreateFontDescriptorsFromURL(fileURL as CFURL) {
            if #available(iOS 13.0, *) {
                CTFontManagerRegisterFontDescriptors(ctFontDescriptorArray, .process, true) { errors, done -> Bool in
                    return true
                }
            } else {
                // Fallback on earlier versions
                CTFontManagerRegisterFontsForURL(fileURL as CFURL, .process, nil)
            }
            let count = CFArrayGetCount(ctFontDescriptorArray)
            for i in 0..<count {
                let valuePointer = CFArrayGetValueAtIndex(ctFontDescriptorArray, CFIndex(i))
                let ctFontDescriptor = unsafeBitCast(valuePointer, to: CTFontDescriptor.self)
                let ctFontName = unsafeBitCast(CTFontDescriptorCopyAttribute(ctFontDescriptor, kCTFontNameAttribute), to: CFString.self)
                print("CTFONT \(ctFontName) \(fileURL)")
                userFontDescriptors[ctFontName as String] = ctFontDescriptor
            }
        }
    }
    return userFontDescriptors
}

extension FolioReaderCenter {

    
}

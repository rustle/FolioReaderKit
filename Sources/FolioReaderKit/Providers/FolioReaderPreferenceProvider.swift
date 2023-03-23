//
//  FolioReaderPreferenceProvider.swift
//  AEXML
//
//  Created by 京太郎 on 2021/9/23.
//

import Foundation

public protocol FolioReaderPreferenceProvider: AnyObject {
    func preference(nightMode defaults: Bool) -> Bool

    func preference(setNightMode value: Bool)

    func preference(themeMode defaults: Int) -> Int

    func preference(setThemeMode defaults: Int)

    func preference(currentFont defaults: String) -> String

    func preference(setCurrentFont value: String)

    func preference(currentFontSize defaults: String) -> String

    func preference(setCurrentFontSize value: String)

    func preference(currentFontWeight defaults: String) -> String

    func preference(setCurrentFontWeight value: String)

    func preference(currentAudioRate defaults: Int) -> Int

    func preference(setCurrentAudioRate value: Int)

    func preference(currentHighlightStyle defaults: Int) -> Int

    func preference(setCurrentHighlightStyle value: Int)

    func preference(currentMediaOverlayStyle defaults: Int) -> Int

    func preference(setCurrentMediaOverlayStyle value: Int)

    func preference(currentScrollDirection defaults: Int) -> Int

    func preference(setCurrentScrollDirection value: Int)

    func preference(currentNavigationMenuIndex defaults: Int) -> Int

    func preference(setCurrentNavigationMenuIndex value: Int)

    func preference(currentAnnotationMenuIndex defaults: Int) -> Int

    func preference(setCurrentAnnotationMenuIndex value: Int)

    func preference(currentNavigationMenuBookListSyle defaults: Int) -> Int

    func preference(setCurrentNavigationMenuBookListStyle value: Int)

    func preference(currentVMarginLinked defaults: Bool) -> Bool

    func preference(setCurrentVMarginLinked value: Bool)

    func preference(currentMarginTop defaults: Int) -> Int

    func preference(setCurrentMarginTop value: Int)

    func preference(currentMarginBottom defaults: Int) -> Int

    func preference(setCurrentMarginBottom value: Int)

    func preference(currentHMarginLinked defaults: Bool) -> Bool

    func preference(setCurrentHMarginLinked value: Bool)

    func preference(currentMarginLeft defaults: Int) -> Int

    func preference(setCurrentMarginLeft value: Int)

    func preference(currentMarginRight defaults: Int) -> Int

    func preference(setCurrentMarginRight value: Int)

    func preference(currentLetterSpacing defaults: Int) -> Int

    func preference(setCurrentLetterSpacing value: Int)

    func preference(currentLineHeight defaults: Int) -> Int

    func preference(setCurrentLineHeight value: Int)

    func preference(currentTextIndent defaults: Int) -> Int

    func preference(setCurrentTextIndent value: Int)

    func preference(doWrapPara defaults: Bool) -> Bool

    func preference(setDoWrapPara value: Bool)

    func preference(doClearClass defaults: Bool) -> Bool

    func preference(setDoClearClass value: Bool)

    func preference(styleOverride defaults: Int) -> Int

    func preference(setStyleOverride value: Int)

    func preference(structuralStyle defaults: Int) -> Int

    func preference(setStructuralStyle value: Int)

    func preference(structuralTocLevel defaults: Int) -> Int

    func preference(setStructuralTocLevel value: Int)

    //MARK: - Profile

    func preference(listProfile filter: String?) -> [String]

    func preference(saveProfile name: String)

    func preference(loadProfile name: String)

    func preference(removeProfile name: String)
}

public class FolioReaderDummyPreferenceProvider: FolioReaderPreferenceProvider {
    let folioReader: FolioReader

    public init(_ folioReader: FolioReader) {
        self.folioReader = folioReader
    }

    public func preference(nightMode defaults: Bool) -> Bool {
        defaults
    }

    public func preference(setNightMode value: Bool) {}

    public func preference(themeMode defaults: Int) -> Int {
        defaults
    }

    public func preference(setThemeMode defaults: Int) {}

    public func preference(currentFont defaults: String) -> String {
        defaults
    }

    public func preference(setCurrentFont value: String) {}

    public func preference(currentFontSize defaults: String) -> String {
        defaults
    }

    public func preference(setCurrentFontSize value: String) {}

    public func preference(currentFontWeight defaults: String) -> String {
        defaults
    }

    public func preference(setCurrentFontWeight value: String) {}

    public func preference(currentAudioRate defaults: Int) -> Int {
        defaults
    }

    public func preference(setCurrentAudioRate value: Int) {}

    public func preference(currentHighlightStyle defaults: Int) -> Int {
        defaults
    }

    public func preference(setCurrentHighlightStyle value: Int) {}

    public func preference(currentMediaOverlayStyle defaults: Int) -> Int {
        defaults
    }

    public func preference(setCurrentMediaOverlayStyle value: Int) {}

    public func preference(currentScrollDirection defaults: Int) -> Int {
        defaults
    }

    public func preference(setCurrentScrollDirection value: Int) {}

    public func preference(currentNavigationMenuIndex defaults: Int) -> Int {
        defaults
    }

    public func preference(setCurrentNavigationMenuIndex value: Int) {}

    public func preference(currentAnnotationMenuIndex defaults: Int) -> Int {
        defaults
    }

    public func preference(setCurrentAnnotationMenuIndex value: Int) {}

    public func preference(currentNavigationMenuBookListSyle defaults: Int) -> Int {
        defaults
    }

    public func preference(setCurrentNavigationMenuBookListStyle value: Int) {}

    public func preference(currentMarginTop defaults: Int) -> Int {
        defaults
    }

    public func preference(currentVMarginLinked defaults: Bool) -> Bool {
        defaults
    }

    public func preference(setCurrentVMarginLinked value: Bool) {}

    public func preference(setCurrentMarginTop value: Int) {}

    public func preference(currentMarginBottom defaults: Int) -> Int {
        defaults
    }

    public func preference(setCurrentMarginBottom value: Int) {}

    public func preference(currentMarginLeft defaults: Int) -> Int {
        defaults
    }

    public func preference(setCurrentMarginLeft value: Int) {}

    public func preference(currentMarginRight defaults: Int) -> Int {
        defaults
    }

    public func preference(setCurrentMarginRight value: Int) {}

    public func preference(currentHMarginLinked defaults: Bool) -> Bool {
        defaults
    }

    public func preference(setCurrentHMarginLinked value: Bool) {}

    public func preference(currentLetterSpacing defaults: Int) -> Int {
        defaults
    }

    public func preference(setCurrentLetterSpacing value: Int) {}

    public func preference(currentLineHeight defaults: Int) -> Int {
        defaults
    }

    public func preference(setCurrentLineHeight value: Int) {}

    public func preference(currentTextIndent defaults: Int) -> Int {
        defaults
    }

    public func preference(setCurrentTextIndent value: Int) {}
    public func preference(doWrapPara defaults: Bool) -> Bool {
        defaults
    }

    public func preference(setDoWrapPara value: Bool) {}

    public func preference(doClearClass defaults: Bool) -> Bool {
        defaults
    }

    public func preference(setDoClearClass value: Bool) {}

    public func preference(styleOverride defaults: Int) -> Int {
        defaults
    }

    public func preference(setStyleOverride value: Int) {}

    public func preference(structuralStyle defaults: Int) -> Int {
        defaults
    }

    public func preference(setStructuralTocLevel value: Int) {}

    public func preference(structuralTocLevel defaults: Int) -> Int {
        defaults

    }

    public func preference(setStructuralStyle value: Int) {}

    public func preference(listProfile filter: String?) -> [String] {
        ["Default"]
    }

    public func preference(saveProfile name: String) {}

    public func preference(loadProfile name: String) {}

    public func preference(removeProfile name: String) {}
}

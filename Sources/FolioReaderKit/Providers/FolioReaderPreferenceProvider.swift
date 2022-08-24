//
//  FolioReaderPreferenceProvider.swift
//  AEXML
//
//  Created by 京太郎 on 2021/9/23.
//

import Foundation

@objc public protocol FolioReaderPreferenceProvider: AnyObject {
    
    @objc func preference(nightMode defaults: Bool) -> Bool
    
    @objc func preference(setNightMode value: Bool)
    
    @objc func preference(themeMode defaults: Int) -> Int
    
    @objc func preference(setThemeMode defaults: Int)

    @objc func preference(currentFont defaults: String) -> String
    
    @objc func preference(setCurrentFont value: String)

    @objc func preference(currentFontSize defaults: String) -> String

    @objc func preference(setCurrentFontSize value: String)

    @objc func preference(currentFontWeight defaults: String) -> String

    @objc func preference(setCurrentFontWeight value: String)

    @objc func preference(currentAudioRate defaults: Int) -> Int
    
    @objc func preference(setCurrentAudioRate value: Int)
    
    @objc func preference(currentHighlightStyle defaults: Int) -> Int
    
    @objc func preference(setCurrentHighlightStyle value: Int)
    
    @objc func preference(currentMediaOverlayStyle defaults: Int) -> Int
    
    @objc func preference(setCurrentMediaOverlayStyle value: Int)
    
    @objc func preference(currentScrollDirection defaults: Int) -> Int
    
    @objc func preference(setCurrentScrollDirection value: Int)
    
    @objc func preference(currentNavigationMenuIndex defaults: Int) -> Int
    
    @objc func preference(setCurrentNavigationMenuIndex value: Int)
    
    @objc func preference(currentAnnotationMenuIndex defaults: Int) -> Int
    
    @objc func preference(setCurrentAnnotationMenuIndex value: Int)
    
    @objc func preference(currentVMarginLinked defaults: Bool) -> Bool
    
    @objc func preference(setCurrentVMarginLinked value: Bool)
    
    @objc func preference(currentMarginTop defaults: Int) -> Int
    
    @objc func preference(setCurrentMarginTop value: Int)
    
    @objc func preference(currentMarginBottom defaults: Int) -> Int
    
    @objc func preference(setCurrentMarginBottom value: Int)
    
    @objc func preference(currentHMarginLinked defaults: Bool) -> Bool
    
    @objc func preference(setCurrentHMarginLinked value: Bool)
    
    @objc func preference(currentMarginLeft defaults: Int) -> Int
    
    @objc func preference(setCurrentMarginLeft value: Int)
    
    @objc func preference(currentMarginRight defaults: Int) -> Int
    
    @objc func preference(setCurrentMarginRight value: Int)
    
    @objc func preference(currentLetterSpacing defaults: Int) -> Int
    
    @objc func preference(setCurrentLetterSpacing value: Int)
    
    @objc func preference(currentLineHeight defaults: Int) -> Int
    
    @objc func preference(setCurrentLineHeight value: Int)
    
    @objc func preference(currentTextIndent defaults: Int) -> Int
    
    @objc func preference(setCurrentTextIndent value: Int)
    
    @objc func preference(doWrapPara defaults: Bool) -> Bool
    
    @objc func preference(setDoWrapPara value: Bool)
    
    @objc func preference(doClearClass defaults: Bool) -> Bool

    @objc func preference(setDoClearClass value: Bool)

    @objc func preference(styleOverride defaults: Int) -> Int
    
    @objc func preference(setStyleOverride value: Int)
    
    @objc func preference(structuralStyle defaults: Int) -> Int
    
    @objc func preference(setStructuralStyle value: Int)
    
    @objc func preference(structuralTocLevel defaults: Int) -> Int
    
    @objc func preference(setStructuralTocLevel value: Int)
    
    
    //MARK: - Profile
    @objc func preference(listProfile filter: String?) -> [String]
    
    @objc func preference(saveProfile name: String)
    
    @objc func preference(loadProfile name: String)
    
    @objc func preference(removeProfile name: String)
}

public class FolioReaderDummyPreferenceProvider: FolioReaderPreferenceProvider {
    let folioReader: FolioReader
    
    public init(_ folioReader: FolioReader) {
        self.folioReader = folioReader
    }

    public func preference(nightMode defaults: Bool) -> Bool {
        return defaults
    }
    
    public func preference(setNightMode value: Bool) {
        
    }
    
    public func preference(themeMode defaults: Int) -> Int {
        return defaults

    }
    
    public func preference(setThemeMode defaults: Int) {
        
    }
    
    public func preference(currentFont defaults: String) -> String {
        return defaults

    }
    
    public func preference(setCurrentFont value: String) {
        
    }
    
    public func preference(currentFontSize defaults: String) -> String {
        return defaults

    }
    
    public func preference(setCurrentFontSize value: String) {
        
    }
    
    public func preference(currentFontWeight defaults: String) -> String {
        return defaults

    }
    
    public func preference(setCurrentFontWeight value: String) {
        
    }
    
    public func preference(currentAudioRate defaults: Int) -> Int {
        return defaults

    }
    
    public func preference(setCurrentAudioRate value: Int) {
        
    }
    
    public func preference(currentHighlightStyle defaults: Int) -> Int {
        return defaults

    }
    
    public func preference(setCurrentHighlightStyle value: Int) {
        
    }
    
    public func preference(currentMediaOverlayStyle defaults: Int) -> Int {
        return defaults

    }
    
    public func preference(setCurrentMediaOverlayStyle value: Int) {
        
    }
    
    public func preference(currentScrollDirection defaults: Int) -> Int {
        return defaults

    }
    
    public func preference(setCurrentScrollDirection value: Int) {
        
    }
    
    public func preference(currentNavigationMenuIndex defaults: Int) -> Int {
        return defaults

    }
    
    public func preference(setCurrentNavigationMenuIndex value: Int) {
        
    }

    public func preference(currentAnnotationMenuIndex defaults: Int) -> Int {
        return defaults
    }
    
    public func preference(setCurrentAnnotationMenuIndex value: Int) {
        
    }
    
    public func preference(currentMarginTop defaults: Int) -> Int {
        return defaults

    }
    
    public func preference(currentVMarginLinked defaults: Bool) -> Bool {
        return defaults
    }
    
    public func preference(setCurrentVMarginLinked value: Bool) {
        
    }
    
    public func preference(setCurrentMarginTop value: Int) {
        
    }
    
    public func preference(currentMarginBottom defaults: Int) -> Int {
        return defaults

    }
    
    public func preference(setCurrentMarginBottom value: Int) {
        
    }
    
    public func preference(currentMarginLeft defaults: Int) -> Int {
        return defaults

    }
    
    public func preference(setCurrentMarginLeft value: Int) {
        
    }
    
    public func preference(currentMarginRight defaults: Int) -> Int {
        return defaults

    }
    
    public func preference(setCurrentMarginRight value: Int) {
        
    }
    
    public func preference(currentHMarginLinked defaults: Bool) -> Bool {
        return defaults
    }
    
    public func preference(setCurrentHMarginLinked value: Bool) {
        
    }
    
    public func preference(currentLetterSpacing defaults: Int) -> Int {
        return defaults

    }
    
    public func preference(setCurrentLetterSpacing value: Int) {
        
    }
    
    public func preference(currentLineHeight defaults: Int) -> Int {
        return defaults

    }
    
    public func preference(setCurrentLineHeight value: Int) {
        
    }
    
    public func preference(currentTextIndent defaults: Int) -> Int {
        return defaults
    }
    
    public func preference(setCurrentTextIndent value: Int) {
        
    }
    public func preference(doWrapPara defaults: Bool) -> Bool {
        return defaults

    }
    
    public func preference(setDoWrapPara value: Bool) {
        
    }
    
    public func preference(doClearClass defaults: Bool) -> Bool {
        return defaults

    }
    
    public func preference(setDoClearClass value: Bool) {
        
    }
    
    public func preference(styleOverride defaults: Int) -> Int {
        return defaults
    }
    
    public func preference(setStyleOverride value: Int) {
        
    }
    
    public func preference(structuralStyle defaults: Int) -> Int {
        return defaults
    }
    
    public func preference(setStructuralTocLevel value: Int) {
        
    }
    
    public func preference(structuralTocLevel defaults: Int) -> Int {
        return defaults
    }
    
    public func preference(setStructuralStyle value: Int) {
        
    }
    
    public func preference(listProfile filter: String?) -> [String] {
        return ["Default"]
    }
    
    
    
    public func preference(saveProfile name: String) {
        
    }
    
    public func preference(loadProfile name: String) {
        
    }
    
    public func preference(removeProfile name: String) {
        
    }
}

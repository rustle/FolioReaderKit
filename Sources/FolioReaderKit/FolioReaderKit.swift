//
//  FolioReaderKit.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 08/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Internal constants

internal let kApplicationDocumentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
internal let kCurrentFontFamily = "com.folioreader.kCurrentFontFamily"
internal let kCurrentFontSize = "com.folioreader.kCurrentFontSize"
internal let kCurrentFontWeight = "com.folioreader.kCurrentFontWeight"

internal let kCurrentAudioRate = "com.folioreader.kCurrentAudioRate"
internal let kCurrentHighlightStyle = "com.folioreader.kCurrentHighlightStyle"
internal let kCurrentMediaOverlayStyle = "com.folioreader.kMediaOverlayStyle"
internal let kCurrentScrollDirection = "com.folioreader.kCurrentScrollDirection"
internal let kNightMode = "com.folioreader.kNightMode"
internal let kThemeMode = "com.folioreader.kThemeMode"
internal let kCurrentTOCMenu = "com.folioreader.kCurrentTOCMenu"
internal let kCurrentMarginTop = "com.folioreader.kCurrentMarginTop"
internal let kCurrentMarginBottom = "com.folioreader.kCurrentMarginBottom"
internal let kCurrentMarginLeft = "com.folioreader.kCurrentMarginLeft"
internal let kCurrentMarginRight = "com.folioreader.kCurrentMarginRight"
internal let kCurrentLetterSpacing = "com.folioreader.kCurrentLetterSpacing"
internal let kCurrentLineHeight = "com.folioreader.kCurrentLineHeight"

internal let kHighlightRange = 30
internal let kReuseCellIdentifier = "com.folioreader.Cell.ReuseIdentifier"

public enum FolioReaderError: Error, LocalizedError {
    case bookNotAvailable
    case errorInContainer
    case errorInOpf
    case authorNameNotAvailable
    case coverNotAvailable
    case invalidImage(path: String)
    case titleNotAvailable
    case fullPathEmpty

    public var errorDescription: String? {
        switch self {
        case .bookNotAvailable:
            return "Book not found"
        case .errorInContainer, .errorInOpf:
            return "Invalid book format"
        case .authorNameNotAvailable:
            return "Author name not available"
        case .coverNotAvailable:
            return "Cover image not available"
        case let .invalidImage(path):
            return "Invalid image at path: " + path
        case .titleNotAvailable:
            return "Book title not available"
        case .fullPathEmpty:
            return "Book corrupted"
        }
    }
}

/// Defines the media overlay and TTS selection
///
/// - `default`: The background is colored
/// - underline: The underlined is colored
/// - textColor: The text is colored
public enum MediaOverlayStyle: Int {
    case `default`
    case underline
    case textColor

    init() {
        self = .default
    }

    func className() -> String {
        return "mediaOverlayStyle\(self.rawValue)"
    }
}

/// FolioReader actions delegate
@objc public protocol FolioReaderDelegate: class {
    
    /// Did finished loading book.
    ///
    /// - Parameters:
    ///   - folioReader: The FolioReader instance
    ///   - book: The Book instance
    @objc optional func folioReader(_ folioReader: FolioReader, didFinishedLoading book: FRBook)
    
    /// Called when reader did closed.
    ///
    /// - Parameter folioReader: The FolioReader instance
    @objc optional func folioReaderDidClose(_ folioReader: FolioReader)
    
    /// Called when reader did closed.
    @available(*, deprecated, message: "Use 'folioReaderDidClose(_ folioReader: FolioReader)' instead.")
    @objc optional func folioReaderDidClosed()
}

/// Main Library class with some useful constants and methods
open class FolioReader: NSObject {

    public override init() { }

    deinit {
        removeObservers()
    }

    /// Custom unzip path
    open var unzipPath: String?

    /// FolioReaderDelegate
    open weak var delegate: FolioReaderDelegate?
    
    var readerContainer: FolioReaderContainer?
    open weak var readerAudioPlayer: FolioReaderAudioPlayer?
    open weak var readerCenter: FolioReaderCenter? {
        return self.readerContainer?.centerViewController
    }

    /// Check if reader is open
    var isReaderOpen = false

    /// Check if reader is open and ready
    var isReaderReady = false

    /// Check if layout needs to change to fit Right To Left
    var needsRTLChange: Bool {
        return (self.readerContainer?.book.spine.isRtl == true && self.readerContainer?.readerConfig.scrollDirection == .horizontal)
    }

    func isNight<T>(_ f: T, _ l: T) -> T {
        return (self.nightMode == true ? f : l)
    }

    /// UserDefault for the current ePub file.
    fileprivate var defaults: FolioReaderUserDefaults {
        return FolioReaderUserDefaults(withIdentifier: self.readerContainer?.readerConfig.identifier)
    }

    // Add necessary observers
    fileprivate func addObservers() {
        removeObservers()
        NotificationCenter.default.addObserver(self, selector: #selector(saveReaderState), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveReaderState), name: UIApplication.willTerminateNotification, object: nil)
    }

    /// Remove necessary observers
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
    }
}

// MARK: - Present FolioReader

extension FolioReader {

    /// Present a Folio Reader Container modally on a Parent View Controller.
    ///
    /// - Parameters:
    ///   - parentViewController: View Controller that will present the reader container.
    ///   - epubPath: String representing the path on the disk of the ePub file. Must not be nil nor empty string.
	///   - unzipPath: Path to unzip the compressed epub.
    ///   - config: FolioReader configuration.
    ///   - shouldRemoveEpub: Boolean to remove the epub or not. Default true.
    ///   - animated: Pass true to animate the presentation; otherwise, pass false.
    open func presentReader(parentViewController: UIViewController, withEpubPath epubPath: String, unzipPath: String? = nil, andConfig config: FolioReaderConfig, shouldRemoveEpub: Bool = true, animated: Bool = true, folioReaderCenterDelegate: FolioReaderCenterDelegate?) {
        let readerContainer = FolioReaderContainer(withConfig: config, folioReader: self, epubPath: epubPath, unzipPath: unzipPath, removeEpub: shouldRemoveEpub)
        self.readerContainer = readerContainer
        
        parentViewController.present(readerContainer, animated: animated, completion: nil)
        addObservers()
    }
    
    open func prepareReader(parentViewController: UIViewController, withEpubPath epubPath: String, unzipPath: String? = nil, andConfig config: FolioReaderConfig, shouldRemoveEpub: Bool = true, animated: Bool = true, folioReaderCenterDelegate: FolioReaderCenterDelegate?) {
        let readerContainer = FolioReaderContainer(withConfig: config, folioReader: self, epubPath: epubPath, unzipPath: unzipPath, removeEpub: shouldRemoveEpub)
        self.readerContainer = readerContainer
        
        addObservers()
    }
}

// MARK: -  Getters and setters for stored values

extension FolioReader {

    public func register(defaults: [String: Any]) {
        self.defaults.register(defaults: defaults)
    }

    /// Check if current theme is Night mode
    open var nightMode: Bool {
        get { return self.defaults.bool(forKey: kNightMode) }
        set (value) {
            self.defaults.set(value, forKey: kNightMode)

            if let readerCenter = self.readerCenter {
                UIView.animate(withDuration: 0.6, animations: {
                    // _ = readerCenter.currentPage?.webView?.js("nightMode(\(self.nightMode))")
                    readerCenter.pageIndicatorView?.reloadColors()
                    readerCenter.configureNavBar()
                    readerCenter.scrollScrubber?.reloadColors()
                    readerCenter.collectionView.backgroundColor = (self.nightMode == true ? self.readerContainer?.readerConfig.nightModeBackground : UIColor.white)
                }, completion: { (finished: Bool) in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "needRefreshPageMode"), object: nil)
                })
            }
        }
    }
    
    open var themeMode: Int {
        get { return self.defaults.integer(forKey: kThemeMode) }
        set (value) {
            self.defaults.set(value, forKey: kThemeMode)

            if let readerCenter = self.readerCenter {
                UIView.animate(withDuration: 0.6, animations: {
                    _ = readerCenter.currentPage?.webView?.js("themeMode(\(self.themeMode))")
                    readerCenter.pageIndicatorView?.reloadColors()
                    readerCenter.configureNavBar()
                    readerCenter.scrollScrubber?.reloadColors()
                    //readerCenter.collectionView.backgroundColor = (self.themeMode == FolioReaderThemeMode.night.rawValue ? self.readerContainer?.readerConfig.nightModeBackground : UIColor.white)
                    readerCenter.collectionView.backgroundColor = self.readerContainer?.readerConfig.themeModeBackground[self.themeMode]
                }, completion: { (finished: Bool) in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "needRefreshPageMode"), object: nil)
                })
            }
        }
    }

    /// Check current font name. Default .andada
//    open var currentFont: FolioReaderFont {
//        get {
//            guard
//                let rawValue = self.defaults.value(forKey: kCurrentFontFamily) as? Int,
//                let font = FolioReaderFont(rawValue: rawValue) else {
//                    return .andada
//            }
//
//            return font
//        }
//        set (font) {
//            self.defaults.set(font.rawValue, forKey: kCurrentFontFamily)
//            _ = self.readerCenter?.currentPage?.webView?.js("setFontName('\(font.cssIdentifier)')")
//        }
//    }
    
    open var currentFont: String {
        get {
            let fontFamilyName = self.defaults.value(forKey: kCurrentFontFamily) as? String ?? "Georgia"
            return fontFamilyName
        }
        set (fontFamilyName) {
            self.defaults.set(fontFamilyName, forKey: kCurrentFontFamily)
            //_ = self.readerCenter?.currentPage?.webView?.js("setFontName('\(fontFamilyName)')")
            _ = self.readerCenter?.currentPage?.webView?.js("setFolioStyle('\(generateRuntimeStyle().data(using: .utf8)!.base64EncodedString())')")
        }
    }

    /// Check current font size. Default .m
    open var currentFontSize: String {
        get {
            let fontSize = self.defaults.value(forKey: kCurrentFontSize) as? String ?? "20px"
            return fontSize
        }
        set (fontSize) {
            self.defaults.set(fontSize, forKey: kCurrentFontSize)
            _ = self.readerCenter?.currentPage?.webView?.js("setFolioStyle('\(generateRuntimeStyle().data(using: .utf8)!.base64EncodedString())')")
        }
    }
    
    open var currentFontSizeOnly: Int {
        return Int(currentFontSize.replacingOccurrences(of: "px", with: "")) ?? 20
    }

    open var currentFontWeight: String {
        get {
            let fontSize = self.defaults.value(forKey: kCurrentFontWeight) as? String ?? "500"
            return fontSize
        }
        set (fontSize) {
            self.defaults.set(fontSize, forKey: kCurrentFontWeight)
            _ = self.readerCenter?.currentPage?.webView?.js("setFolioStyle('\(generateRuntimeStyle().data(using: .utf8)!.base64EncodedString())')")
        }
    }
    
    /// Check current audio rate, the speed of speech voice. Default 0
    open var currentAudioRate: Int {
        get { return self.defaults.integer(forKey: kCurrentAudioRate) }
        set (value) {
            self.defaults.set(value, forKey: kCurrentAudioRate)
        }
    }

    /// Check the current highlight style.Default 0
    open var currentHighlightStyle: Int {
        get { return self.defaults.integer(forKey: kCurrentHighlightStyle) }
        set (value) {
            self.defaults.set(value, forKey: kCurrentHighlightStyle)
        }
    }

    /// Check the current Media Overlay or TTS style
    open var currentMediaOverlayStyle: MediaOverlayStyle {
        get {
            guard let rawValue = self.defaults.value(forKey: kCurrentMediaOverlayStyle) as? Int,
                let style = MediaOverlayStyle(rawValue: rawValue) else {
                return MediaOverlayStyle.default
            }
            return style
        }
        set (value) {
            self.defaults.set(value.rawValue, forKey: kCurrentMediaOverlayStyle)
        }
    }

    /// Check the current scroll direction. Default .defaultVertical
    open var currentScrollDirection: Int {
        get {
            guard let value = self.defaults.value(forKey: kCurrentScrollDirection) as? Int else {
                return FolioReaderScrollDirection.defaultVertical.rawValue
            }

            return value
        }
        set (value) {
            self.defaults.set(value, forKey: kCurrentScrollDirection)

            let direction = (FolioReaderScrollDirection(rawValue: currentScrollDirection) ?? .defaultVertical)
            self.readerCenter?.setScrollDirection(direction)
        }
    }

    open var currentMenuIndex: Int {
        get { return self.defaults.integer(forKey: kCurrentTOCMenu) }
        set (value) {
            self.defaults.set(value, forKey: kCurrentTOCMenu)
        }
    }
    
    open var currentMarginTop: Int {
        get { return self.defaults.integer(forKey: kCurrentMarginTop)}
        set (value) {
            self.defaults.set(value, forKey: kCurrentMarginTop)
            let direction = (FolioReaderScrollDirection(rawValue: currentScrollDirection) ?? .defaultVertical)
            self.readerCenter?.setScrollDirection(direction)
        }
    }

    open var currentMarginBottom: Int {
        get { return self.defaults.integer(forKey: kCurrentMarginBottom)}
        set (value) {
            self.defaults.set(value, forKey: kCurrentMarginBottom)
            let direction = (FolioReaderScrollDirection(rawValue: currentScrollDirection) ?? .defaultVertical)
            self.readerCenter?.setScrollDirection(direction)
        }
    }

    open var currentMarginLeft: Int {
        get { return self.defaults.integer(forKey: kCurrentMarginLeft)}
        set (value) {
            self.defaults.set(value, forKey: kCurrentMarginLeft)
            let direction = (FolioReaderScrollDirection(rawValue: currentScrollDirection) ?? .defaultVertical)
            self.readerCenter?.setScrollDirection(direction)
        }
    }

    open var currentMarginRight: Int {
        get { return self.defaults.integer(forKey: kCurrentMarginRight)}
        set (value) {
            self.defaults.set(value, forKey: kCurrentMarginRight)
            let direction = (FolioReaderScrollDirection(rawValue: currentScrollDirection) ?? .defaultVertical)
            self.readerCenter?.setScrollDirection(direction)
        }
    }
    
    open var currentLetterSpacing: Int {
        get { return self.defaults.integer(forKey: kCurrentLetterSpacing) }
        set (value) {
            self.defaults.set(value, forKey: kCurrentLetterSpacing)
            _ = self.readerCenter?.currentPage?.webView?.js("setFolioStyle('\(generateRuntimeStyle().data(using: .utf8)!.base64EncodedString())')")
        }
    }
    
    open var currentLineHeight: Int {
        get { return self.defaults.integer(forKey: kCurrentLineHeight) }
        set (value) {
            self.defaults.set(value, forKey: kCurrentLineHeight)
            _ = self.readerCenter?.currentPage?.webView?.js("setFolioStyle('\(generateRuntimeStyle().data(using: .utf8)!.base64EncodedString())')")
        }
    }
    

    @objc dynamic open var savedPositionForCurrentBook: [String: Any]? {
        get {
            guard let bookId = self.readerContainer?.book.name else {
                return nil
            }
            return self.defaults.value(forKey: bookId) as? [String : Any]
        }
        set {
            guard let bookId = self.readerContainer?.book.name else {
                return
            }
            self.defaults.set(newValue, forKey: bookId)
        }
    }
}

// MARK: - Metadata

extension FolioReader {

    // TODO QUESTION: The static `getCoverImage` function used the shared instance before and ignored the `unzipPath` parameter.
    // Should we properly implement the parameter (what has been done now) or should change the API to only use the current FolioReader instance?

    /**
     Read Cover Image and Return an `UIImage`
     */
    open class func getCoverImage(_ epubPath: String, unzipPath: String? = nil) throws -> UIImage {
        return try FREpubParser().parseCoverImage(epubPath, unzipPath: unzipPath)
    }

    open class func getTitle(_ epubPath: String, unzipPath: String? = nil) throws -> String {
        return try FREpubParser().parseTitle(epubPath, unzipPath: unzipPath)
    }

    open class func getAuthorName(_ epubPath: String, unzipPath: String? = nil) throws-> String {
        return try FREpubParser().parseAuthorName(epubPath, unzipPath: unzipPath)
    }
}

// MARK: - Exit, save and close FolioReader

extension FolioReader {

    /// Save Reader state, book, page and scroll offset.
    @objc open func saveReaderState() {
        guard isReaderOpen else {
            return
        }

        guard let currentPage = self.readerCenter?.currentPage, let webView = currentPage.webView else {
            return
        }

        let position = [
            "pageNumber": (self.readerCenter?.currentPageNumber ?? 0),
            "pageOffsetX": webView.scrollView.contentOffset.x,
            "pageOffsetY": webView.scrollView.contentOffset.y
            ] as [String : Any]

        self.savedPositionForCurrentBook = position
    }

    /// Closes and save the reader current instance.
    open func close() {
        self.saveReaderState()
        self.isReaderOpen = false
        self.isReaderReady = false
        self.readerAudioPlayer?.stop(immediate: true)
        self.defaults.set(0, forKey: kCurrentTOCMenu)
        self.delegate?.folioReaderDidClose?(self)
    }
}

// MARK: - CSS Style


extension FolioReader {
    
    open func generateRuntimeStyle() -> String {
        let letterSpacing = Float(currentLetterSpacing * 2 * currentFontSizeOnly) / Float(100)
        let lineHeight = (100 + (currentLineHeight - 2) * 5)    //90% ~ 160%
        let textIndent = (Float(letterSpacing) + Float(currentFontSizeOnly)) * 2
        
        var style = ""
        style += """
        
        p {
            font-family: \(currentFont) !important;
            font-size: \(currentFontSize) !important;
            font-weight: \(currentFontWeight) !important;
            letter-spacing: \(letterSpacing)px !important;
            line-height: \(lineHeight)% !important;
            text-indent: \(textIndent)px !important;
            -webkit-hyphens: auto !important;
        }
        
        p > span {
            letter-spacing: \(letterSpacing)px !important;
            line-height: \(lineHeight)% !important;
        }
        
        """
        
        for fontName in UIFont.fontNames(forFamilyName: currentFont) {
//            if let fontURL = readerCenter?.userFonts[fontName] {
            if let fontDescriptor = readerCenter?.userFontDescriptors[fontName] {
//                let ctFont = CTFontCreateWithName(fontName as CFString, CGFloat(currentFontSizeOnly), nil)
//                let ctFontSymbolicTrait = CTFontGetSymbolicTraits(ctFont)
//                let ctFontTraits = CTFontCopyTraits(ctFont)
//                let ctFontURL = unsafeBitCast(CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontURLAttribute), to: CFURL.self)
                guard let ctFontURL = CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontURLAttribute),  CFGetTypeID(ctFontURL) == CFURLGetTypeID() else {
                    continue
                }
                var isItalic = false
                var isBold = false
                
                var cssFontWeight = "normal"
                
                if let ctFontTraits = CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontTraitsAttribute), CFGetTypeID(ctFontTraits) == CFDictionaryGetTypeID() {
                    if let ctFontSymbolicTrait = CFDictionaryGetValue(
                        (ctFontTraits as! CFDictionary),
                        unsafeBitCast(kCTFontSymbolicTrait, to: UnsafeRawPointer.self))  {
                        
                        var symTraitVal = UInt32()
                        CFNumberGetValue(unsafeBitCast(ctFontSymbolicTrait, to: CFNumber.self), CFNumberType.intType, &symTraitVal)
                        
                        isItalic = symTraitVal & CTFontSymbolicTraits.traitItalic.rawValue > 0
                        isBold = symTraitVal & CTFontSymbolicTraits.traitBold.rawValue > 0
                        
                        cssFontWeight = isBold ? "bold" : "normal"
                    }
    //                let isItalic = ctFontSymbolicTrait.contains(.traitItalic)
    //                let isBold = ctFontSymbolicTrait.contains(.traitBold)
                    
                    
                    if let weightRef = CFDictionaryGetValue(
                        (ctFontTraits as! CFDictionary),
                        unsafeBitCast(kCTFontWeightTrait, to: UnsafeRawPointer.self)) {
                        
                        var weightValue = Float()
                        CFNumberGetValue(unsafeBitCast(weightRef, to: CFNumber.self), CFNumberType.floatType, &weightValue)
                        if weightValue < -0.49 {
                            cssFontWeight = "100"   //thin
                        } else if weightValue < -0.29 {
                            cssFontWeight = "200"   //extralight
                        } else if weightValue < -0.19 {
                            cssFontWeight = "300"   //light
                        } else if weightValue < 0.01 {
                            cssFontWeight = "400"   //normal
                        } else if weightValue < 0.21 {
                            cssFontWeight = "500"   //medium
                        } else if weightValue < 0.31 {
                            cssFontWeight = "600"   //semibold
                        } else if weightValue < 0.41 {
                            cssFontWeight = "700"   //bold
                        } else if weightValue < 0.61 {
                            cssFontWeight = "800"   //extrabold
                        } else {
                            cssFontWeight = "900"   //heavy
                        }
                    }
                }
                
                style += """
                
                @font-face {
                    font-family: \(currentFont);
                    font-style: \(isItalic ? "italic" : "normal");
                    font-weight: \(cssFontWeight);
                    src: url('\(ctFontURL as! CFURL)');
                }
                
                """
                
            }
        }
        
        return style
    }
}

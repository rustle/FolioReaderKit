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
    
    @objc optional func folioReaderHighlightProvider(_ folioReader: FolioReader) -> FolioReaderHighlightProvider
    
    @objc optional func folioReaderPreferenceProvider(_ folioReader: FolioReader) -> FolioReaderPreferenceProvider
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
    open weak var readerConfig: FolioReaderConfig? {
        return self.readerContainer?.readerConfig
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
        readerContainer.modalPresentationStyle = .fullScreen
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

    /// Check if current theme is Night mode
    open var nightMode: Bool {
        get {
            delegate?.folioReaderPreferenceProvider?(self).preference(nightMode: false) ?? false
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setNightMode: value)

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
        get {
            return delegate?.folioReaderPreferenceProvider?(self).preference(themeMode: 0) ?? 0
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setThemeMode: value)
            
            if let readerCenter = self.readerCenter {
                UIView.animate(withDuration: 0.6, animations: {
                    _ = readerCenter.currentPage?.webView?.js("themeMode(\(self.themeMode))")
                    readerCenter.pageIndicatorView?.reloadColors()
                    readerCenter.configureNavBar()
                    readerCenter.scrollScrubber?.reloadColors()
                    //readerCenter.collectionView.backgroundColor = (self.themeMode == FolioReaderThemeMode.night.rawValue ? self.readerContainer?.readerConfig.nightModeBackground : UIColor.white)
                    if let backgroundColor = self.readerContainer?.readerConfig.themeModeBackground[self.themeMode] {
                        readerCenter.collectionView.backgroundColor = backgroundColor
                        if let page = readerCenter.currentPage {
                            page.panDeadZoneTop?.backgroundColor = backgroundColor
                            page.panDeadZoneBot?.backgroundColor = backgroundColor
                        }
                    }
                }, completion: { (finished: Bool) in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "needRefreshPageMode"), object: nil)
                })
            }
        }
    }

    open var currentFont: String {
        get {
            return delegate?.folioReaderPreferenceProvider?(self).preference(currentFont: "Georgia") ?? "Georgia"
        }
        set (fontFamilyName) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentFont: fontFamilyName)
            updateRuntimStyle(delay: 0.4)
        }
    }

    /// Check current font size. Default .m
    open var currentFontSize: String {
        get {
            return delegate?.folioReaderPreferenceProvider?(self).preference(currentFontSize: "20px") ?? "20px"
        }
        set (fontSize) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentFontSize: fontSize)
            updateRuntimStyle(delay: 0.4)
        }
    }
    
    open var currentFontSizeOnly: Int {
        return Int(currentFontSize.replacingOccurrences(of: "px", with: "")) ?? 20
    }

    open var currentFontWeight: String {
        get {
            return delegate?.folioReaderPreferenceProvider?(self).preference(currentFontWeight: "500") ?? "500"
        }
        set (fontWeight) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentFontWeight: fontWeight)
            updateRuntimStyle(delay: 0.4)
        }
    }
    
    /// Check current audio rate, the speed of speech voice. Default 0
    open var currentAudioRate: Int {
        get {
            delegate?.folioReaderPreferenceProvider?(self).preference(currentAudioRate: 1) ?? 1
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentAudioRate: value)
        }
    }

    /// Check the current highlight style.Default 0
    open var currentHighlightStyle: Int {
        get {
            return delegate?.folioReaderPreferenceProvider?(self)
                .preference(currentHighlightStyle: HighlightStyle.yellow.rawValue)
                ?? HighlightStyle.yellow.rawValue
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentHighlightStyle: value)
        }
    }

    /// Check the current Media Overlay or TTS style
    open var currentMediaOverlayStyle: MediaOverlayStyle {
        get {
            guard let rawValue = delegate?.folioReaderPreferenceProvider?(self).preference(currentMediaOverlayStyle: MediaOverlayStyle.default.rawValue),
                let style = MediaOverlayStyle(rawValue: rawValue) else {
                return MediaOverlayStyle.default
            }
            return style
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentMediaOverlayStyle: value.rawValue)
        }
    }

    /// Check the current scroll direction. Default .defaultVertical
    open var currentScrollDirection: Int {
        get {
            return delegate?.folioReaderPreferenceProvider?(self)
                .preference(currentScrollDirection: FolioReaderScrollDirection.defaultVertical.rawValue)
                ?? FolioReaderScrollDirection.defaultVertical.rawValue
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentScrollDirection: value)

            let direction = (FolioReaderScrollDirection(rawValue: currentScrollDirection) ?? .defaultVertical)
            self.readerCenter?.setScrollDirection(direction)
        }
    }

    open var currentMenuIndex: Int {
        get {
            return delegate?.folioReaderPreferenceProvider?(self).preference(currentMenuIndex: 0) ?? 0
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentMenuIndex: value)
        }
    }
    
    open var currentMarginTop: Int {
        get {
            delegate?.folioReaderPreferenceProvider?(self).preference(currentMarginTop: 0) ?? 0
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentMarginTop: value)
            updateViewerLayout(delay: 0.2)
        }
    }

    open var currentMarginBottom: Int {
        get {
            delegate?.folioReaderPreferenceProvider?(self).preference(currentMarginBottom: 0) ?? 0
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentMarginBottom: value)
            updateViewerLayout(delay: 0.2)
        }
    }

    open var currentMarginLeft: Int {
        get {
            delegate?.folioReaderPreferenceProvider?(self).preference(currentMarginLeft: 0) ?? 0
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentMarginLeft: value)
            updateRuntimStyle(delay: 0.4)
        }
    }

    open var currentMarginRight: Int {
        get {
            delegate?.folioReaderPreferenceProvider?(self).preference(currentMarginRight: 0) ?? 0
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentMarginRight: value)
            updateRuntimStyle(delay: 0.4)

        }
    }
    
    open var currentLetterSpacing: Int {
        get {
            delegate?.folioReaderPreferenceProvider?(self).preference(currentLetterSpacing: 0) ?? 0
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentLetterSpacing: value)
            updateRuntimStyle(delay: 0.4)
        }
    }
    
    open var currentLineHeight: Int {
        get {
            delegate?.folioReaderPreferenceProvider?(self).preference(currentLineHeight: 0) ?? 0
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentLineHeight: value)
            updateRuntimStyle(delay: 0.4)
        }
    }

    open var doWrapPara: Bool {
        get {
            delegate?.folioReaderPreferenceProvider?(self).preference(doWrapPara: false) ?? false
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setDoWrapPara: value)
        }
    }
    
    open var doClearClass: Bool {
        get {
            delegate?.folioReaderPreferenceProvider?(self).preference(doClearClass: false) ?? false
        }
        set (value) {
            delegate?.folioReaderPreferenceProvider?(self).preference(setDoClearClass: value)
        }
    }
    
    @objc dynamic open var savedPositionForCurrentBook: [String: Any]? {
        get {
            delegate?.folioReaderPreferenceProvider?(self).preference(savedPosition: nil)
        }
        set {
            guard let value = newValue else { return }
            delegate?.folioReaderPreferenceProvider?(self).preference(setSavedPosition: value)
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
        self.delegate?.folioReaderPreferenceProvider?(self).preference(setCurrentMenuIndex: 0)
        self.delegate?.folioReaderDidClose?(self)
    }
}

// MARK: - CSS Style


extension FolioReader {
    
    func updateViewerLayout(delay bySecond: Double) {
        guard let readerCenter = readerCenter else { return }
        
        readerCenter.layoutAdapting = true
        
        readerCenter.currentPage?.setNeedsLayout()
        
        readerCenter.updateScrollPosition(delay: bySecond) {
            readerCenter.layoutAdapting = false
        }
    }
    
    func updateRuntimStyle(delay bySecond: Double) {
        guard let readerCenter = readerCenter else { return }

        readerCenter.layoutAdapting = true
        
        readerCenter.currentPage?.webView?.js(
            """
            setFolioStyle(
            '\(generateRuntimeStyle()
                .data(using: .utf8)!
                .base64EncodedString())'
            )
            """
        ) { _ in
            readerCenter.updateScrollPosition(delay: bySecond) {
                readerCenter.layoutAdapting = false
            }
        }
    }
    
    func generateRuntimeStyle() -> String {
        let letterSpacing = Float(currentLetterSpacing * 2 * currentFontSizeOnly) / Float(100)
        let lineHeight = Decimal((currentLineHeight + 10) * 5) / 100 + 1    //1.5 ~ 2.05
        let textIndent = (Float(letterSpacing) + Float(currentFontSizeOnly)) * 2
        let marginTopEm = Decimal(1)
        let marginBottonEm = lineHeight - 1
        
        
        var style = ""
        style += """
        
        p {
            font-family: \(currentFont) !important;
            font-size: \(currentFontSize) !important;
            font-weight: \(currentFontWeight) !important;
            letter-spacing: \(letterSpacing)px !important;
            line-height: \(lineHeight) !important;
            text-indent: \(textIndent)px !important;
            text-align: justify !important;
            margin: \(marginTopEm)em 0 \(marginBottonEm)em 0 !important;
            -webkit-hyphens: auto !important;
        }
        
        span {
            letter-spacing: \(letterSpacing)px !important;
            line-height: \(lineHeight) !important;
        }
        
        """
        
        if let pageWidth = readerCenter?.pageWidth, let pageHeight = readerCenter?.pageHeight {
            let marginTop = 0 //CGFloat(currentMarginTop) / 200 * pageHeight
            let marginBottom = 0 //CGFloat(currentMarginBottom) / 200 * pageHeight
            let marginLeft = CGFloat(currentMarginLeft) / 200 * pageWidth
            let marginRight = CGFloat(currentMarginRight) / 200 * pageWidth
            
            style += """
            
            body {
                padding: \(marginTop)px \(marginRight)px \(marginBottom)px \(marginLeft)px !important;
                overflow: hidden !important;
            }
            
            @page {
                margin: \(marginTop)px \(marginRight)px \(marginBottom)px \(marginLeft)px !important;
            }
            
            """
        }
        
        
        for fontName in UIFont.fontNames(forFamilyName: currentFont) {
//            if let fontURL = readerCenter?.userFonts[fontName] {
            guard let fontDescriptor = readerCenter?.userFontDescriptors[fontName] else {
                continue
            }
//                let ctFont = CTFontCreateWithName(fontName as CFString, CGFloat(currentFontSizeOnly), nil)
//                let ctFontSymbolicTrait = CTFontGetSymbolicTraits(ctFont)
//                let ctFontTraits = CTFontCopyTraits(ctFont)
//                let ctFontURL = unsafeBitCast(CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontURLAttribute), to: CFURL.self)
            guard let ctFontURL = CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontURLAttribute),
                  CFGetTypeID(ctFontURL) == CFURLGetTypeID(),
                  let fontURL = ctFontURL as? URL else {
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
            
            //prepare font hardlink
            guard let resourceBasePath = self.readerContainer?.book.smils.basePath else {
                continue
            }
            if self.readerContainer?.readerConfig.debug.contains(.htmlStyling) ?? false {
                print("generateRuntimeStyle \(resourceBasePath)")
            }
            
            let folioResPath = resourceBasePath.appendingPathComponent("_folio_res")

            let toFontPath = folioResPath.appendingPathComponent(fontURL.lastPathComponent)

            do {
                if !FileManager.default.fileExists(atPath: folioResPath) {
                    try FileManager.default.createDirectory(atPath: folioResPath, withIntermediateDirectories: false, attributes: nil)
                }
                
                if self.readerContainer?.readerConfig.debug.contains(.htmlStyling) ?? false  {
                    print("generateRuntimeStyle linkItem \(fontURL.path) \(toFontPath)")
                }

                if FileManager.default.fileExists(atPath: toFontPath) {
                    try FileManager.default.removeItem(atPath: toFontPath)
                }
                try FileManager.default.linkItem(atPath: fontURL.path, toPath: toFontPath)
            } catch {
                continue
            }
            
            style += """
            
            @font-face {
                font-family: \(currentFont);
                font-style: \(isItalic ? "italic" : "normal");
                font-weight: \(cssFontWeight);
                src: url('\(toFontPath)');
            }
            
            """
        }
        
        return style
    }
}

@objc public protocol FolioReaderPreferenceProvider: class {
    
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
    
    @objc func preference(currentMenuIndex defaults: Int) -> Int
    
    @objc func preference(setCurrentMenuIndex value: Int)
    
    @objc func preference(currentMarginTop defaults: Int) -> Int
    
    @objc func preference(setCurrentMarginTop value: Int)
    
    @objc func preference(currentMarginBottom defaults: Int) -> Int
    
    @objc func preference(setCurrentMarginBottom value: Int)
    
    @objc func preference(currentMarginLeft defaults: Int) -> Int
    
    @objc func preference(setCurrentMarginLeft value: Int)
    
    @objc func preference(currentMarginRight defaults: Int) -> Int
    
    @objc func preference(setCurrentMarginRight value: Int)
    
    @objc func preference(currentLetterSpacing defaults: Int) -> Int
    
    @objc func preference(setCurrentLetterSpacing value: Int)
    
    @objc func preference(currentLineHeight defaults: Int) -> Int
    
    @objc func preference(setCurrentLineHeight value: Int)
    
    @objc func preference(doWrapPara defaults: Bool) -> Bool
    
    @objc func preference(setDoWrapPara value: Bool)
    
    @objc func preference(doClearClass defaults: Bool) -> Bool

    @objc func preference(setDoClearClass value: Bool)

    @objc func preference(savedPosition defaults: [String: Any]?) -> [String: Any]?
    
    @objc func preference(setSavedPosition value: [String: Any])
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
    
    public func preference(currentMenuIndex defaults: Int) -> Int {
        return defaults

    }
    
    public func preference(setCurrentMenuIndex value: Int) {
        
    }
    
    public func preference(currentMarginTop defaults: Int) -> Int {
        return defaults

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
    
    public func preference(savedPosition defaults: [String : Any]?) -> [String : Any]? {
        return defaults

    }
    
    public func preference(setSavedPosition value: [String : Any]) {
        
    }
    
}

@objc public protocol FolioReaderHighlightProvider: class {

    /// Save a Highlight with completion block
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - completion: Completion block.
    @objc func folioReaderHighlight(_ folioReader: FolioReader, added highlight: Highlight, completion: Completion?)
    
    /// Remove a Highlight by ID
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - highlightId: The ID to be removed
    @objc func folioReaderHighlight(_ folioReader: FolioReader, removedId highlightId: String)
    
    /// Update a Highlight by ID
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - highlightId: The ID to be removed
    ///   - type: The `HighlightStyle`
    @objc func folioReaderHighlight(_ folioReader: FolioReader, updateById highlightId: String, type style: HighlightStyle)
    
    /// Return a Highlight by ID
    ///
    /// - Parameter:
    ///   - readerConfig: Current folio reader configuration.
    ///   - highlightId: The ID to be removed
    ///   - page: Page number
    /// - Returns: Return a Highlight
    @objc func folioReaderHighlight(_ folioReader: FolioReader, getById highlightId: String) -> Highlight?
    
    /// Return a list of Highlights with a given ID
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - bookId: Book ID
    ///   - page: Page number
    /// - Returns: Return a list of Highlights
    @objc func folioReaderHighlight(_ folioReader: FolioReader, allByBookId bookId: String, andPage page: NSNumber?) -> [Highlight]
    
    /// Return all Highlights
    ///
    /// - Parameter readerConfig: - readerConfig: Current folio reader configuration.
    /// - Returns: Return all Highlights
    @objc func folioReaderHighlight(_ folioReader: FolioReader) -> [Highlight]
    
    @objc func folioReaderHighlight(_ folioReader: FolioReader, saveNoteFor highlight: Highlight)
    
}

public class FolioReaderDummyHighlightProvider: FolioReaderHighlightProvider {
    
    public init() {
        
    }
    public func folioReaderHighlight(_ folioReader: FolioReader, added highlight: Highlight, completion: Completion?) {
        
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, removedId highlightId: String) {
        
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, updateById highlightId: String, type style: HighlightStyle) {
        
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, getById highlightId: String) -> Highlight? {
        return nil
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, allByBookId bookId: String, andPage page: NSNumber?) -> [Highlight] {
        return []
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader) -> [Highlight] {
        return []
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, saveNoteFor highlight: Highlight) {
        
    }
    

}

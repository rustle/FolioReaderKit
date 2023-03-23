//
//  ViewController.swift
//  Example
//
//  Created by Heberti Almeida on 08/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import EpubCore
import FolioReaderKit
import RealmSwift

class ViewController: UIViewController {

    @IBOutlet weak var bookOne: UIButton?
    @IBOutlet weak var bookTwo: UIButton?
    //let folioReader = FolioReader()

    var preferenceProvider: FolioReaderPreferenceProvider?
    var highlightProvider: FolioReaderHighlightProvider?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.bookOne?.tag = Epub.bookOne.rawValue
        self.bookTwo?.tag = Epub.bookTwo.rawValue

        self.setCover(self.bookOne, index: 0)
        self.setCover(self.bookTwo, index: 1)
    }

    private func readerConfiguration(forEpub epub: Epub) -> FolioReaderConfig {
        let config = FolioReaderConfig(withIdentifier: epub.readerIdentifier)
        config.shouldHideNavigationOnTap = epub.shouldHideNavigationOnTap
        config.scrollDirection = epub.scrollDirection
        //config.savedPositionForCurrentBook = ["pageNumber": Int(6), "pageOffsetX": CGFloat(6150), "pageOffsetY": CGFloat(0.0)]
        config.allowSharing = false //Broken as of now
        config.enableTTS = false
        config.debug.formUnion([.htmlStyling])

        // See more at FolioReaderConfig.swift
//        config.canChangeScrollDirection = false
//        config.enableTTS = false
//        config.displayTitle = true
//        config.allowSharing = false
//        config.tintColor = UIColor.blueColor()
//        config.toolBarTintColor = UIColor.redColor()
//        config.toolBarBackgroundColor = UIColor.purpleColor()
//        config.menuTextColor = UIColor.brownColor()
//        config.menuBackgroundColor = UIColor.lightGrayColor()
//        config.hidePageIndicator = true
//        config.realmConfiguration = Realm.Configuration(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("highlights.realm"))

        // Custom sharing quote background
        config.quoteCustomBackgrounds = []
        if let image = UIImage(named: "demo-bg") {
            let customImageQuote = QuoteImage(withImage: image, alpha: 0.6, backgroundColor: UIColor.black)
            config.quoteCustomBackgrounds.append(customImageQuote)
        }

        let textColor = UIColor(red:0.86, green:0.73, blue:0.70, alpha:1.0)
        let customColor = UIColor(red:0.30, green:0.26, blue:0.20, alpha:1.0)
        let customQuote = QuoteImage(withColor: customColor, alpha: 1.0, textColor: textColor)
        config.quoteCustomBackgrounds.append(customQuote)

        return config
    }

    fileprivate func open(epub: Epub) {
        guard let bookPath = epub.bookPath else {
            return
        }

        let readerConfiguration = self.readerConfiguration(forEpub: epub)
        let folioReader = FolioReader()
        folioReader.delegate = self
        folioReader.presentReader(
            parentViewController: self,
            withEpubPath: bookPath,
            unzipPath: makeFolioReaderUnzipPath()?.path,
            andConfig: readerConfiguration,
            shouldRemoveEpub: false,
            folioReaderCenterDelegate: nil)
        
        //TEST
        for fontFamilyName in UIFont.familyNames {
            for fontName in UIFont.fontNames(forFamilyName: fontFamilyName) {
                print("Font: \(fontFamilyName) \(fontName)")
            }
        }
    }

    private func setCover(_ button: UIButton?, index: Int) {
        guard
            let epub = Epub(rawValue: index),
            let bookPath = epub.bookPath else {
                return
        }

        do {
            let image = try FolioReader.getCoverImage(bookPath)

            button?.setBackgroundImage(image, for: .normal)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func makeFolioReaderUnzipPath() -> URL? {
        guard let cacheDirectory = try? FileManager.default.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true) else {
            return nil
        }
        let folioReaderUnzipped = cacheDirectory.appendingPathComponent("FolioReaderUnzipped", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folioReaderUnzipped.path) {
            do {
                try FileManager.default.createDirectory(at: folioReaderUnzipped, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        
        return folioReaderUnzipped
    }
}

extension ViewController: FolioReaderDelegate {
    func folioReaderPreferenceProvider(_ folioReader: FolioReader) -> FolioReaderPreferenceProvider {
        if let preferenceProvider = preferenceProvider {
            return preferenceProvider
        } else {
            let preferenceProvider = FolioReaderUserDefaultsPreferenceProvider(folioReader)
            self.preferenceProvider = preferenceProvider
            
            return preferenceProvider
        }
    }

    func folioReaderHighlightProvider(_ folioReader: FolioReader) -> FolioReaderHighlightProvider {
        if let highlightProvider = highlightProvider {
            return highlightProvider
        } else {
            let highlightProvider = FolioReaderRealmHighlightProvider(folioReader)
            self.highlightProvider = highlightProvider
            
            return highlightProvider
        }
    }
}

open class HighlightRealm: Object {
    @objc open dynamic var bookId: String!
    @objc open dynamic var content: String!
    @objc open dynamic var contentPost: String!
    @objc open dynamic var contentPre: String!
    @objc open dynamic var date: Date!
    @objc open dynamic var highlightId: String!
    @objc open dynamic var page: Int = 0
    @objc open dynamic var type: Int = 0
    @objc open dynamic var startOffset: Int = -1
    @objc open dynamic var endOffset: Int = -1
    @objc open dynamic var noteForHighlight: String?
    @objc open dynamic var cfiStart: String?
    @objc open dynamic var cfiEnd: String?

    override open class func primaryKey()-> String {
        return "highlightId"
    }

    func fromHighlight(_ highlight: Highlight) {
        bookId = highlight.bookId
        content = highlight.content
        contentPost = highlight.contentPost
        contentPre = highlight.contentPre
        date = highlight.date
        highlightId = highlight.highlightId
        page = highlight.page
        type = highlight.type
        startOffset = highlight.startOffset
        endOffset = highlight.endOffset
        noteForHighlight = highlight.noteForHighlight
        cfiStart = highlight.cfiStart
        cfiEnd = highlight.cfiEnd
    }

    func toHighlight() -> Highlight {
        let highlight = Highlight()
        highlight.bookId = bookId
        highlight.content = content
        highlight.contentPost = contentPost
        highlight.contentPre = contentPre
        highlight.date = date
        highlight.highlightId = highlightId
        highlight.page = page
        highlight.type = type
        highlight.style = HighlightStyle.classForStyle(type)
        highlight.startOffset = startOffset
        highlight.endOffset = endOffset
        highlight.noteForHighlight = noteForHighlight
        highlight.cfiStart = cfiStart
        highlight.cfiEnd = cfiEnd
        
        highlight.encodeContents()
        
        return highlight
    }
}

class FolioReaderUserDefaultsPreferenceProvider: FolioReaderPreferenceProvider {
    
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
    internal let kDoWrapPara = "com.folioreader.kDoWrapPara"
    internal let kDoClearClass = "com.folioreader.kDoClearClass"
    
    let folioReader: FolioReader
    
    init(_ folioReader: FolioReader) {
        self.folioReader = folioReader
        
        // Register initial defaults
        register(defaults: [
            kCurrentFontFamily: FolioReaderFont.andada.rawValue,
            kNightMode: false,
            kThemeMode: FolioReaderThemeMode.day.rawValue,
            kCurrentFontSize: 2,
            kCurrentAudioRate: 1,
            kCurrentHighlightStyle: 0,
            kCurrentTOCMenu: 0,
            kCurrentMediaOverlayStyle: MediaOverlayStyle.default.rawValue,
            kCurrentScrollDirection: FolioReaderScrollDirection.defaultVertical.rawValue
            ])
    }
    
    /// UserDefault for the current ePub file.
    fileprivate var defaults: FolioReaderUserDefaults {
        return FolioReaderUserDefaults(
            withIdentifier: folioReader.readerCenter?.readerContainer?.readerConfig.identifier)
    }

    public func register(defaults: [String: Any]) {
        self.defaults.register(defaults: defaults)
    }

    func preference(nightMode defaults: Bool) -> Bool {
        return self.defaults.bool(forKey: kNightMode)
    }
    
    func preference(setNightMode value: Bool){
        self.defaults.set(value, forKey: kNightMode)
    }
    
    func preference(themeMode defaults: Int) -> Int {
        return self.defaults.integer(forKey: kThemeMode)
    }
    func preference(setThemeMode value: Int) {
        self.defaults.set(value, forKey: kThemeMode)
    }
    
    func preference(currentFont defaults: String) -> String {
        return self.defaults.value(forKey: kCurrentFontFamily) as? String ?? defaults
    }
    func preference(setCurrentFont value: String) {
        self.defaults.set(value, forKey: kCurrentFontFamily)
    }
    
    func preference(currentFontSize defaults: String) -> String {
        return self.defaults.value(forKey: kCurrentFontSize) as? String ?? defaults
    }
    func preference(setCurrentFontSize value: String) {
        self.defaults.set(value, forKey: kCurrentFontSize)
    }
    
    func preference(currentFontWeight defaults: String) -> String {
        return self.defaults.value(forKey: kCurrentFontWeight) as? String ?? defaults
    }
    func preference(setCurrentFontWeight value: String) {
        self.defaults.set(value, forKey: kCurrentFontWeight)
    }
    
    func preference(currentAudioRate defaults: Int) -> Int {
        return self.defaults.integer(forKey: kCurrentAudioRate)
    }
    func preference(setCurrentAudioRate value: Int) {
        self.defaults.set(value, forKey: kCurrentAudioRate)
    }
    
    func preference(currentHighlightStyle defaults: Int) -> Int {
        return self.defaults.integer(forKey: kCurrentHighlightStyle)
    }
    func preference(setCurrentHighlightStyle value: Int) {
        self.defaults.set(value, forKey: kCurrentHighlightStyle)
    }
    
    func preference(currentMediaOverlayStyle defaults: Int) -> Int {
        return self.defaults.value(forKey: kCurrentMediaOverlayStyle) as? Int ?? defaults
    }
    func preference(setCurrentMediaOverlayStyle value: Int) {
        self.defaults.set(value, forKey: kCurrentMediaOverlayStyle)
    }
    
    func preference(currentScrollDirection defaults: Int) -> Int {
        return self.defaults.value(forKey: kCurrentScrollDirection) as? Int ?? defaults
    }
    func preference(setCurrentScrollDirection value: Int) {
        self.defaults.set(value, forKey: kCurrentScrollDirection)
    }
    
    func preference(currentMenuIndex defaults: Int) -> Int {
        return self.defaults.integer(forKey: kCurrentTOCMenu)
    }
    func preference(setCurrentMenuIndex value: Int) {
        self.defaults.set(value, forKey: kCurrentTOCMenu)
    }
    
    func preference(currentMarginTop defaults: Int) -> Int {
        return self.defaults.integer(forKey: kCurrentMarginTop)
    }
    func preference(setCurrentMarginTop value: Int) {
        self.defaults.set(value, forKey: kCurrentMarginTop)
    }
    
    func preference(currentMarginBottom defaults: Int) -> Int {
        return self.defaults.integer(forKey: kCurrentMarginBottom)
    }
    func preference(setCurrentMarginBottom value: Int) {
        self.defaults.set(value, forKey: kCurrentMarginBottom)
    }
    
    func preference(currentMarginLeft defaults: Int) -> Int {
        return self.defaults.integer(forKey: kCurrentMarginLeft)
    }
    func preference(setCurrentMarginLeft value: Int) {
        self.defaults.set(value, forKey: kCurrentMarginLeft)
    }
    
    func preference(currentMarginRight defaults: Int) -> Int {
        return self.defaults.integer(forKey: kCurrentMarginRight)
    }
    func preference(setCurrentMarginRight value: Int) {
        self.defaults.set(value, forKey: kCurrentMarginRight)
    }
    
    func preference(currentLetterSpacing defaults: Int) -> Int {
        return self.defaults.integer(forKey: kCurrentLetterSpacing)
    }
    func preference(setCurrentLetterSpacing value: Int) {
        self.defaults.set(value, forKey: kCurrentLetterSpacing)
    }
    
    func preference(currentLineHeight defaults: Int) -> Int {
        return self.defaults.integer(forKey: kCurrentLineHeight)
    }
    func preference(setCurrentLineHeight value: Int) {
        self.defaults.set(value, forKey: kCurrentLineHeight)
    }
    
    func preference(doWrapPara defaults: Bool) -> Bool {
        return self.defaults.bool(forKey: kDoWrapPara)
    }
    func preference(setDoWrapPara value: Bool) {
        self.defaults.set(value, forKey: kDoWrapPara)
    }
    
    func preference(doClearClass defaults: Bool) -> Bool {
        return self.defaults.bool(forKey: kDoClearClass)
    }
    func preference(setDoClearClass value: Bool) {
        self.defaults.set(value, forKey: kDoClearClass)
    }
    
    func preference(savedPosition defaults: [String: Any]?) -> [String: Any]? {
        guard let bookId = folioReader.readerCenter?.readerContainer?.book.name else {
            return defaults
        }
        return self.defaults.value(forKey: bookId) as? [String : Any]
    }
    
    func preference(setSavedPosition value: [String: Any]) {
        guard let bookId = folioReader.readerCenter?.readerContainer?.book.name else {
            return
        }
        self.defaults.set(value, forKey: bookId)
    }
}

public class FolioReaderRealmHighlightProvider: FolioReaderHighlightProvider {
    let folioReader: FolioReader
    var realmConfiguration = Realm.Configuration(schemaVersion: 2)
    
    init(_ folioReader: FolioReader) {
        self.folioReader = folioReader
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, added highlight: Highlight, completion: Completion?) {
        print("highlight added \(highlight)")
        
        guard let readerConfig = folioReader.readerCenter?.readerContainer?.readerConfig else { return }
        do {
            let highlightRealm = HighlightRealm()
            highlightRealm.fromHighlight(highlight)
            
            let realm = try Realm(configuration: realmConfiguration)
            realm.beginWrite()
            realm.add(highlightRealm, update: .all)
            try realm.commitWrite()
            completion?(nil)
        } catch let error as NSError {
            print("Error on persist highlight: \(error)")
            completion?(error)
        }
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, removedId highlightId: String) {
        print("highlight removed \(highlightId)")
        
        guard let readerConfig = folioReader.readerCenter?.readerContainer?.readerConfig else { return }
        let predicate = NSPredicate(format:"highlightId = %@", highlightId)

        do {
            let realm = try Realm(configuration: realmConfiguration)
            guard let highlightRealm = realm.objects(HighlightRealm.self).filter(predicate).toArray(HighlightRealm.self).first else { return }
            try realm.write {
                realm.delete(highlightRealm)
            }
        } catch let error as NSError {
            print("Error on remove highlight by id: \(error)")
        }
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, updateById highlightId: String, type style: HighlightStyle) {
        print("highlight updated \(highlightId) \(style)")

        guard let readerConfig = folioReader.readerCenter?.readerContainer?.readerConfig else { return }
        var highlight: HighlightRealm?
        let predicate = NSPredicate(format:"highlightId = %@", highlightId)
        do {
            let realm = try Realm(configuration: realmConfiguration)
            highlight = realm.objects(HighlightRealm.self).filter(predicate).toArray(HighlightRealm.self).first
            realm.beginWrite()

            highlight?.type = style.rawValue

            try realm.commitWrite()
            
        } catch let error as NSError {
            print("Error on updateById: \(error)")
        }

    }

    public func folioReaderHighlight(_ folioReader: FolioReader, getById highlightId: String) -> Highlight? {
        print("highlight getById \(highlightId)")

        guard let readerConfig = folioReader.readerCenter?.readerContainer?.readerConfig else { return nil }
        
        let predicate = NSPredicate(format:"highlightId = %@", highlightId)

        do {
            let realm = try Realm(configuration: realmConfiguration)
            if let highlightRealm = realm.objects(HighlightRealm.self).filter(predicate).toArray(HighlightRealm.self).first {
                return highlightRealm.toHighlight()
            }
        } catch let error as NSError {
            print("Error getting Highlight : \(error)")
        }

        return nil
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, allByBookId bookId: String, andPage page: NSNumber?) -> [Highlight] {
        print("highlight allByBookId \(bookId) \(page ?? 0)")

        guard let readerConfig = folioReader.readerCenter?.readerContainer?.readerConfig else { return [] }

        var highlights: [Highlight]?
        var predicate = NSPredicate(format: "bookId = %@", bookId)
        if let page = page {
            predicate = NSPredicate(format: "bookId = %@ && page = %@", bookId, page)
        }

        do {
            let realm = try Realm(configuration: realmConfiguration)
            highlights = realm.objects(HighlightRealm.self).filter(predicate).toArray(HighlightRealm.self).map {
                $0.toHighlight()
            }.sorted()
            print("highlight allByBookId \(highlights ?? [])")

            return (highlights ?? [])
        } catch let error as NSError {
            print("Error on fetch all by book Id: \(error)")
            return []
        }
    }

    public func folioReaderHighlight(_ folioReader: FolioReader) -> [Highlight] {
        print("highlight all")
        
        guard let readerConfig = folioReader.readerCenter?.readerContainer?.readerConfig else { return [] }

        var highlights: [Highlight]?
        do {
            let realm = try Realm(configuration: realmConfiguration)
            highlights = realm.objects(HighlightRealm.self).toArray(HighlightRealm.self).map {
                $0.toHighlight()
            }
            print("highlight all \(highlights ?? [])")

            return (highlights ?? [])
        } catch let error as NSError {
            print("Error on fetch all: \(error)")
            return []
        }
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, saveNoteFor highlight: Highlight) {
        print("highlight saveNoteFor \(highlight)")

        guard let readerConfig = folioReader.readerCenter?.readerContainer?.readerConfig else { return }
        do {
            let realm = try Realm(configuration: realmConfiguration)
            let predicate = NSPredicate(format:"highlightId = %@", highlight.highlightId)
            if let highlightRealm = realm.objects(HighlightRealm.self).filter(predicate).toArray(HighlightRealm.self).first {
                try realm.write {
                    highlightRealm.noteForHighlight = highlight.noteForHighlight
                    realm.add(highlightRealm, update: .modified)
                }
            }
        } catch let error as NSError {
            print("Error on updateById: \(error)")
        }
        
    }
}

extension Results {
    func toArray<T>(_ ofType: T.Type) -> [T] {
        return compactMap { $0 as? T }
    }
}

// MARK: - IBAction

extension ViewController {
    
    @IBAction func didOpen(_ sender: AnyObject) {
        guard let epub = Epub(rawValue: sender.tag) else {
            return
        }

        self.open(epub: epub)
    }
}


//
//  ViewController.swift
//  Example
//
//  Created by Heberti Almeida on 08/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import FolioReaderKit
import RealmSwift

class ViewController: UIViewController {

    @IBOutlet weak var bookOne: UIButton?
    @IBOutlet weak var bookTwo: UIButton?
    //let folioReader = FolioReader()

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
    
    public func folioReaderHighlight(_ folioReader: FolioReader, added highlight: Highlight, completion: Completion?) {
        print("highlight added \(highlight)")
        
        guard let readerConfig = folioReader.readerCenter?.readerContainer?.readerConfig else { return }
        do {
            let highlightRealm = HighlightRealm()
            highlightRealm.fromHighlight(highlight)
            
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
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
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
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
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
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
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
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
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
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
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
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
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
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

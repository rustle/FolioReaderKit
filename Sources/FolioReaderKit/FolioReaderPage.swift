//
//  FolioReaderPage.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 10/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import SafariServices
import MenuItemKit
import OSLog
import WebKit

/// Protocol which is used from `FolioReaderPage`s.
@objc public protocol FolioReaderPageDelegate: class {

    /**
     Notify that the page will be loaded. Note: The webview content itself is already loaded at this moment. But some java script operations like the adding of class based on click listeners will happen right after this method. If you want to perform custom java script before this happens this method is the right choice. If you want to modify the html content (and not run java script) you have to use `htmlContentForPage()` from the `FolioReaderCenterDelegate`.

     - parameter page: The loaded page
     */
    @objc optional func pageWillLoad(_ page: FolioReaderPage)

    /**
     Notifies that page did load. A page load doesn't mean that this page is displayed right away, use `pageDidAppear` to get informed about the appearance of a page.

     - parameter page: The loaded page
     */
    @objc optional func pageDidLoad(_ page: FolioReaderPage)
    
    /**
     Notifies that page receive tap gesture.
     
     - parameter recognizer: The tap recognizer
     */
    @objc optional func pageTap(_ recognizer: UITapGestureRecognizer)
}

open class FolioReaderPage: UICollectionViewCell, WKNavigationDelegate, UIGestureRecognizerDelegate, WKScriptMessageHandler {
    weak var delegate: FolioReaderPageDelegate?
    weak var readerContainer: FolioReaderContainer?

    /// The index of the current page. Note: The index start at 1!
    open var pageNumber: Int!
    open var webView: FolioReaderWebView?
    open var panDeadZoneTop: UIView?
    open var panDeadZoneBot: UIView?
    
    fileprivate var colorView: UIView!
    fileprivate var shouldShowBar = true
    fileprivate var menuIsVisible = false
    
    var fileURLLoaded = false

    fileprivate var readerConfig: FolioReaderConfig {
        guard let readerContainer = readerContainer else { return FolioReaderConfig() }
        return readerContainer.readerConfig
    }

    fileprivate var book: FRBook {
        guard let readerContainer = readerContainer else { return FRBook() }
        return readerContainer.book
    }

    fileprivate var folioReader: FolioReader {
        guard let readerContainer = readerContainer else { return FolioReader() }
        return readerContainer.folioReader
    }

    // MARK: - View life cicle

    public override init(frame: CGRect) {
        // Init explicit attributes with a default value. The `setup` function MUST be called to configure the current object with valid attributes.
        self.readerContainer = FolioReaderContainer(withConfig: FolioReaderConfig(), folioReader: FolioReader(), epubPath: "")
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear

        NotificationCenter.default.addObserver(self, selector: #selector(refreshPageMode), name: NSNotification.Name(rawValue: "needRefreshPageMode"), object: nil)
    }

    public func setup(withReaderContainer readerContainer: FolioReaderContainer) {
        self.readerContainer = readerContainer
        guard let readerContainer = self.readerContainer else { return }

        if webView == nil {
            webView = FolioReaderWebView(frame: webViewFrame(), readerContainer: readerContainer)
            webView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            webView?.scrollView.showsVerticalScrollIndicator = false
            webView?.scrollView.showsHorizontalScrollIndicator = false
            webView?.backgroundColor = .clear
            webView?.isHidden = true
            webView?.configuration.userContentController.add(self, name: "FolioReaderPage")
            self.contentView.addSubview(webView!)
            if readerConfig.debug.contains(.borderHighlight) {
                webView?.layer.borderWidth = 10
                webView?.layer.borderColor = UIColor.magenta.cgColor
            }
        }
        webView?.navigationDelegate = self

        if panDeadZoneTop == nil {
            panDeadZoneTop = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            panDeadZoneTop?.autoresizingMask = []
            panDeadZoneTop?.backgroundColor = self.readerContainer?.readerConfig.themeModeBackground[self.folioReader.themeMode]
            panDeadZoneTop?.isOpaque = false
            
            let panGeature = UIPanGestureRecognizer(target: self, action: nil)
            panGeature.delegate = self
            panDeadZoneTop?.addGestureRecognizer(panGeature)
            
            self.contentView.addSubview(panDeadZoneTop!)
        }
        
        if panDeadZoneBot == nil {
            panDeadZoneBot = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            panDeadZoneBot?.autoresizingMask = []
            panDeadZoneBot?.backgroundColor = self.readerContainer?.readerConfig.themeModeBackground[self.folioReader.themeMode]
            panDeadZoneBot?.isOpaque = false
            
            let panGeature = UIPanGestureRecognizer(target: self, action: nil)
            panGeature.delegate = self
            panDeadZoneBot?.addGestureRecognizer(panGeature)
            
            self.contentView.addSubview(panDeadZoneBot!)
        }
        
        
        
        if colorView == nil {
            colorView = UIView()
            colorView.backgroundColor = self.readerConfig.nightModeBackground
            webView?.scrollView.addSubview(colorView)
        }

        // Remove all gestures before adding new one
        webView?.gestureRecognizers?.forEach({ gesture in
            webView?.removeGestureRecognizer(gesture)
        })
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.delegate = self
        webView?.addGestureRecognizer(tapGestureRecognizer)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }

    deinit {
        webView?.scrollView.delegate = nil
        webView?.navigationDelegate = nil
        NotificationCenter.default.removeObserver(self)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        webView?.setupScrollDirection()
        let webViewFrame = self.webViewFrame()
        webView?.frame = webViewFrame
        
        let panDeadZoneTopFrame = CGRect(x: 0, y: 0, width: webViewFrame.width, height: webViewFrame.minY)
        panDeadZoneTop?.frame = panDeadZoneTopFrame
        
        let panDeadZoneBotFrame = CGRect(x: 0, y: webViewFrame.maxY, width: webViewFrame.width, height: frame.maxY - webViewFrame.maxY)
        panDeadZoneBot?.frame = panDeadZoneBotFrame
    }

    func webViewFrame() -> CGRect {
        guard (self.readerConfig.hideBars == false) else {
            return bounds
        }
        
        let statusbarHeight = UIApplication.shared.statusBarFrame.size.height
        let navBarHeight = self.folioReader.readerCenter?.navigationController?.navigationBar.frame.size.height ?? CGFloat(0)
        let topComponentTotal = self.readerConfig.shouldHideNavigationOnTap ? 0 : navBarHeight
        let bottomComponentTotal = self.readerConfig.hidePageIndicator ? 0 : self.folioReader.readerCenter?.pageIndicatorHeight ?? CGFloat(0)
        let paddingTop: CGFloat = CGFloat(self.folioReader.currentMarginTop) / 200 * (self.folioReader.readerCenter?.pageHeight ?? CGFloat(0))
        let paddingBottom: CGFloat = CGFloat(self.folioReader.currentMarginBottom) / 200 * (self.folioReader.readerCenter?.pageHeight ?? CGFloat(0))
        
        return CGRect(
            x: bounds.origin.x,
            y: self.readerConfig.isDirection(
                bounds.origin.y + topComponentTotal,
                bounds.origin.y + topComponentTotal + paddingTop,
                bounds.origin.y + topComponentTotal),
            width: bounds.width,
            height: self.readerConfig.isDirection(
                bounds.height - topComponentTotal,
                bounds.height - topComponentTotal - paddingTop - bottomComponentTotal - paddingBottom,
                bounds.height - topComponentTotal)
        )
    }
    
    func webViewFrameVanilla() -> CGRect {
        guard (self.readerConfig.hideBars == false) else {
            return bounds
        }
        
        let statusbarHeight = UIApplication.shared.statusBarFrame.size.height
        let navBarHeight = self.folioReader.readerCenter?.navigationController?.navigationBar.frame.size.height ?? CGFloat(0)
        let navTotal = self.readerConfig.shouldHideNavigationOnTap ? 0 : statusbarHeight + navBarHeight
        let paddingTop: CGFloat = 20
        let paddingBottom: CGFloat = 30
        
        return CGRect(
            x: bounds.origin.x,
            y: self.readerConfig.isDirection(bounds.origin.y + navTotal, bounds.origin.y + navTotal + paddingTop, bounds.origin.y + navTotal),
            width: bounds.width,
            height: self.readerConfig.isDirection(bounds.height - navTotal, bounds.height - navTotal - paddingTop - paddingBottom, bounds.height - navTotal)
        )
    }
    
    func webViewFramePeter() -> CGRect {
        guard (self.readerConfig.hideBars == false) else {
            return bounds
        }

        let statusbarHeight = UIApplication.shared.statusBarFrame.size.height
        let navBarHeight = self.folioReader.readerCenter?.navigationController?.navigationBar.frame.size.height ?? CGFloat(0)
        let navTotal = self.readerConfig.shouldHideNavigationOnTap ? 0 : statusbarHeight + navBarHeight
        let paddingTop: CGFloat = -40
        let paddingBottom: CGFloat = 50

        print("boundsFrame \(bounds)")
        print("statusBarFrame \(UIApplication.shared.statusBarFrame)")
        print("navigationBarFrame \(self.folioReader.readerCenter?.navigationController?.navigationBar.frame)")
        
        var x = bounds.origin.x
        var y = self.readerConfig.isDirection(bounds.origin.y + navTotal, bounds.origin.y + navTotal + paddingTop, bounds.origin.y + navTotal)
        y = navBarHeight
        var width = bounds.width
        var height = self.readerConfig.isDirection(bounds.height - navTotal, bounds.height - navTotal - paddingTop - paddingBottom, bounds.height - navTotal)
        height = bounds.height - navBarHeight - statusbarHeight
        
        var frame = CGRect(x:x, y:y, width: width, height: height)
        frame = frame.insetBy(
            dx: CGFloat((self.folioReader.currentMarginLeft + self.folioReader.currentMarginRight) / 2),
            dy: CGFloat((self.folioReader.currentMarginTop + self.folioReader.currentMarginBottom) / 2))
        frame = frame.offsetBy(
            dx: CGFloat((self.folioReader.currentMarginLeft - self.folioReader.currentMarginRight) / 2),
            dy: CGFloat((self.folioReader.currentMarginTop - self.folioReader.currentMarginBottom) / 2))
        
        print("Frame \(frame)")
        
        return frame
    }

    func loadHTMLString(_ htmlContent: String!, baseURL: URL!) {
        // Load the html into the webview
        webView?.alpha = 0
        webView?.loadHTMLString(htmlContent, baseURL: baseURL)
        
//        var result = webView?.js("removeOuterTable()")
//        Logger().info("removeOuterTable: \(result ?? "empty")")
//        
//        
//        result = webView?.js("getHTML()")
//        Logger().info("getHTML: \(result ?? "empty")")
    }
    
    func loadFileURLOnceOnly(_ URL: URL, allowingReadAccessTo readAccessURL: URL) {
        if fileURLLoaded {
            return
        }
        
        if (webView?.loadFileURL(URL, allowingReadAccessTo: readAccessURL)) != nil {
            fileURLLoaded = true
        }
    }

    // MARK: - WKNavigation Delegate

    open func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard let webView = webView as? FolioReaderWebView else {
            return
        }

        delegate?.pageWillLoad?(self)
    }

    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let webView = webView as? FolioReaderWebView else {
            return
        }

        // Add the custom class based onClick listener
        self.setupClassBasedOnClickListeners()

        refreshPageMode()

        if self.readerConfig.enableTTS && !self.book.hasAudio {
            webView.js("wrappingSentencesWithinPTags()")

            if let audioPlayer = self.folioReader.readerAudioPlayer, (audioPlayer.isPlaying() == true) {
                audioPlayer.readCurrentSentence()
            }
        }

        let direction: ScrollDirection = self.folioReader.needsRTLChange ? .positive(withConfiguration: self.readerConfig) : .negative(withConfiguration: self.readerConfig)

        if (self.folioReader.readerCenter?.pageScrollDirection == direction &&
            self.folioReader.readerCenter?.isScrolling == true &&
            self.readerConfig.scrollDirection != .horizontalWithVerticalContent) {
            scrollPageToBottom()
        }

        UIView.animate(withDuration: 0.2, animations: {webView.alpha = 1}, completion: { finished in
            webView.isColors = false
            self.webView?.createMenu(options: false)
        })
//        webView.js("document.readyState") { _ in
//            self.delegate?.pageDidLoad?(self)
//        }
        
        let overlayColor = readerConfig.mediaOverlayColor!
        let colors = "\"\(overlayColor.hexString(false))\", \"\(overlayColor.highlightColor().hexString(false))\""
        webView.js("setMediaOverlayStyleColors(\(colors))")
    }

    open func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let handledAction = handlePolicy(for: navigationAction)
        let policy: WKNavigationActionPolicy = handledAction ? .allow : .cancel
        decisionHandler(policy)
    }

    private func handlePolicy(for navigationAction: WKNavigationAction) -> Bool {
        let request = navigationAction.request
        guard
            let webView = webView as? FolioReaderWebView,
            let scheme = request.url?.scheme else {
                return true
        }

        guard let url = request.url else { return false }

        if scheme == "highlight" || scheme == "highlight-with-note" {
            shouldShowBar = false

            guard let decoded = url.absoluteString.removingPercentEncoding else { return false }
            let index = decoded.index(decoded.startIndex, offsetBy: 12)
            let rect = NSCoder.cgRect(for: String(decoded[index...]))

            webView.createMenu(options: true, onHighlight: true)
            webView.setMenuVisible(true, andRect: rect)
            menuIsVisible = true

            return false
        } else if scheme == "play-audio" {
            guard let decoded = url.absoluteString.removingPercentEncoding else { return false }
            let index = decoded.index(decoded.startIndex, offsetBy: 13)
            let playID = String(decoded[index...])
            let chapter = self.folioReader.readerCenter?.getCurrentChapter()
            let href = chapter?.href ?? ""
            self.folioReader.readerAudioPlayer?.playAudio(href, fragmentID: playID)

            return false
        } else if scheme == "file" {

            let anchorFromURL = url.fragment

            // Handle internal url
            if !url.pathExtension.isEmpty {
                let pathComponent = (self.book.opfResource.href as NSString?)?.deletingLastPathComponent
                guard let base = ((pathComponent == nil || pathComponent?.isEmpty == true) ? self.book.name : pathComponent) else {
                    return true
                }

                let path = url.path
                let splitedPath = path.components(separatedBy: base)

                // Return to avoid crash
                if (splitedPath.count <= 1 || splitedPath[1].isEmpty) {
                    return true
                }

                let href = splitedPath[1].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                let hrefPage = (self.folioReader.readerCenter?.findPageByHref(href) ?? 0) + 1

                if (hrefPage == pageNumber) {
                    // Handle internal #anchor
                    if anchorFromURL != nil {
                        handleAnchor(anchorFromURL!, avoidBeginningAnchors: false, animated: true)
                        return false
                    }
                } else {
                    self.folioReader.readerCenter?.changePageWith(href: href, animated: true)
                }
                return false
            }

            // Handle internal #anchor
            if anchorFromURL != nil {
                handleAnchor(anchorFromURL!, avoidBeginningAnchors: false, animated: true)
                return false
            }

            return true
        } else if scheme == "mailto" {
            print("Email")
            return true
        } else if url.absoluteString != "about:blank" && scheme.contains("http") && navigationAction.navigationType == .linkActivated {
            let safariVC = SFSafariViewController(url: request.url!)
            safariVC.view.tintColor = self.readerConfig.tintColor
            self.folioReader.readerCenter?.present(safariVC, animated: true, completion: nil)
            return false
        } else {
            // Check if the url is a custom class based onClick listerner
            var isClassBasedOnClickListenerScheme = false
            for listener in self.readerConfig.classBasedOnClickListeners {

                if scheme == listener.schemeName,
                    let absoluteURLString = request.url?.absoluteString,
                    let range = absoluteURLString.range(of: "/clientX=") {
                    let baseURL = String(absoluteURLString[..<range.lowerBound])
                    let positionString = String(absoluteURLString[range.lowerBound...])
                    if let point = getEventTouchPoint(fromPositionParameterString: positionString) {
                        let attributeContentString = (baseURL.replacingOccurrences(of: "\(scheme)://", with: "").removingPercentEncoding)
                        // Call the on click action block
                        listener.onClickAction(attributeContentString, point)
                        // Mark the scheme as class based click listener scheme
                        isClassBasedOnClickListenerScheme = true
                    }
                }
            }

            if isClassBasedOnClickListenerScheme == false {
                // Try to open the url with the system if it wasn't a custom class based click listener
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.openURL(url)
                    return false
                }
            } else {
                return false
            }
        }

        return true
    }

    fileprivate func getEventTouchPoint(fromPositionParameterString positionParameterString: String) -> CGPoint? {
        // Remove the parameter names: "/clientX=188&clientY=292" -> "188&292"
        var positionParameterString = positionParameterString.replacingOccurrences(of: "/clientX=", with: "")
        positionParameterString = positionParameterString.replacingOccurrences(of: "clientY=", with: "")
        // Separate both position values into an array: "188&292" -> [188],[292]
        let positionStringValues = positionParameterString.components(separatedBy: "&")
        // Multiply the raw positions with the screen scale and return them as CGPoint
        if
            positionStringValues.count == 2,
            let xPos = Int(positionStringValues[0]),
            let yPos = Int(positionStringValues[1]) {
            return CGPoint(x: xPos, y: yPos)
        }
        return nil
    }

    // MARK: WKScriptMessageHandler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        //This function handles the events coming from javascript. We'll configure the javascript side of this later.
        //We can access properties through the message body, like this:
        guard let response = message.body as? String else { return }
        if response == "BridgeFinished" {
            var preprocessor = ""
            if folioReader.doClearClass {
                preprocessor.append("removeBodyClass();tweakStyleOnly();")
            }
            if folioReader.doWrapPara {
                preprocessor.append("reParagraph();removePSpace();")
            }
            preprocessor.append("setFolioStyle('\(self.folioReader.generateRuntimeStyle().data(using: .utf8)!.base64EncodedString())');")
            
            self.webView?.js(preprocessor) {_ in
                delay(1.0) {
                    self.injectHighlights()

                    self.delegate?.pageDidLoad?(self)
                }
            }
        } else if self.readerConfig.debug.contains(.htmlStyling) {
            print("userContentController response\n\(response)")
        }
    }
    
    func injectHighlights() {
        guard let bookId = (self.book.name as NSString?)?.deletingPathExtension else { return }
        guard let highlights = self.folioReader.delegate?.folioReaderHighlight?(self.folioReader, allByBookId: bookId, andPage: pageNumber as NSNumber?) else { return }
        guard highlights.isEmpty == false else { return }
        let encoder = JSONEncoder()

        for item in highlights {
            do {
                let serializedData = try encoder.encode(item)
                let encodedData = serializedData.base64EncodedString()
                self.webView?.js("injectHighlight('\(encodedData)')") {_ in
                    
                }
            } catch {
                
            }
        }
    }
    
    // MARK: Gesture recognizer

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view is FolioReaderWebView {
            if otherGestureRecognizer is UILongPressGestureRecognizer {
                if UIMenuController.shared.isMenuVisible {
                    webView?.setMenuVisible(false)
                }
                return false
            }
            return true
        }
        return false
    }

    @objc open func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        self.delegate?.pageTap?(recognizer)
        
        if let _navigationController = self.folioReader.readerCenter?.navigationController, (_navigationController.isNavigationBarHidden == true) {
            webView?.js("getSelectedText()") { selected in
                guard (selected == nil || selected?.isEmpty == true) else {
                    return
                }
            
                let delay = 0.4 * Double(NSEC_PER_SEC) // 0.4 seconds * nanoseconds per seconds
                let dispatchTime = (DispatchTime.now() + (Double(Int64(delay)) / Double(NSEC_PER_SEC)))
                
                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    if (self.shouldShowBar == true && self.menuIsVisible == false) {
                        self.folioReader.readerCenter?.toggleBars()
                    }
                })
            }
        } else if (self.readerConfig.shouldHideNavigationOnTap == true) {
            self.folioReader.readerCenter?.hideBars()
            self.menuIsVisible = false
        }
    }

    // MARK: - Public scroll postion setter

    /**
     Scrolls the page to a given offset

     - parameter offset:   The offset to scroll
     - parameter animated: Enable or not scrolling animation
     */
    open func scrollPageToOffset(_ offset: CGFloat, animated: Bool) {
        let pageOffsetPoint = self.readerConfig.isDirection(CGPoint(x: 0, y: offset), CGPoint(x: offset, y: 0), CGPoint(x: 0, y: offset))
        webView?.scrollView.setContentOffset(pageOffsetPoint, animated: animated)
    }

    /**
     Scrolls the page to bottom
     */
    open func scrollPageToBottom() {
        guard let webView = webView else { return }
        let bottomOffset = self.readerConfig.isDirection(
            CGPoint(x: 0, y: webView.scrollView.contentSize.height - webView.scrollView.bounds.height),
            CGPoint(x: webView.scrollView.contentSize.width - webView.scrollView.bounds.width, y: 0),
            CGPoint(x: webView.scrollView.contentSize.width - webView.scrollView.bounds.width, y: 0)
        )

        if bottomOffset.forDirection(withConfiguration: self.readerConfig) >= 0 {
            DispatchQueue.main.async {
                self.webView?.scrollView.setContentOffset(bottomOffset, animated: false)
            }
        }
    }

    /**
     Handdle #anchors in html, get the offset and scroll to it

     - parameter anchor:                The #anchor
     - parameter avoidBeginningAnchors: Sometimes the anchor is on the beggining of the text, there is not need to scroll
     - parameter animated:              Enable or not scrolling animation
     */
    open func handleAnchor(_ anchor: String,  avoidBeginningAnchors: Bool, animated: Bool) {
        if !anchor.isEmpty {
            getAnchorOffset(anchor) { offset in
                switch self.readerConfig.scrollDirection {
                case .vertical, .defaultVertical:
                    let isBeginning = (offset < self.frame.forDirection(withConfiguration: self.readerConfig) * 0.5)
                    
                    if !avoidBeginningAnchors {
                        self.scrollPageToOffset(offset, animated: animated)
                    } else if avoidBeginningAnchors && !isBeginning {
                        self.scrollPageToOffset(offset, animated: animated)
                    }
                case .horizontal, .horizontalWithVerticalContent:
                    self.scrollPageToOffset(offset, animated: animated)
                }
            }
        }
    }

    // MARK: Helper

    /**
     Get the #anchor offset in the page

     - parameter anchor: The #anchor id
     - returns: The element offset ready to scroll
     */
    func getAnchorOffset(_ anchor: String, completion: @escaping ((CGFloat) -> ())) {
        let horizontal = self.readerConfig.scrollDirection == .horizontal
        webView?.js("getAnchorOffset('\(anchor)', \(horizontal.description))") { strOffset in
            guard let strOffset = strOffset else {
                completion(CGFloat(0))
                return
            }
            completion(CGFloat((strOffset as NSString).floatValue))
        }
    }

    // MARK: Mark ID

    /**
     Audio Mark ID - marks an element with an ID with the given class and scrolls to it

     - parameter identifier: The identifier
     */
    func audioMarkID(_ identifier: String) {
        guard let currentPage = self.folioReader.readerCenter?.currentPage else {
            return
        }

        let playbackActiveClass = self.book.playbackActiveClass
        currentPage.webView?.js("audioMarkID('\(playbackActiveClass)','\(identifier)')")
    }

    // MARK: UIMenu visibility

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard let webView = webView else { return false }

        if UIMenuController.shared.menuItems?.count == 0 {
            webView.isColors = false
            webView.createMenu(options: false)
        }

        if !webView.isShare && !webView.isColors && false {
            webView.js("getSelectedText()") { result in
                guard let result = result, result.components(separatedBy: " ").count == 1 else {
                    webView.isOneWord = false
                    return
                }
                webView.isOneWord = true
                webView.createMenu(options: false)
            }
        }

        return super.canPerformAction(action, withSender: sender)
    }

    // MARK: ColorView fix for horizontal layout
    @objc func refreshPageMode() {
        guard let webView = webView else { return }

        if (self.folioReader.nightMode == true) {
            // omit create webView and colorView
            // let script = "document.documentElement.offsetHeight"
            // let contentHeight = webView.stringByEvaluatingJavaScript(from: script)
            // let frameHeight = webView.frame.height
            // let lastPageHeight = frameHeight * CGFloat(webView.pageCount) - CGFloat(Double(contentHeight!)!)
            // colorView.frame = CGRect(x: webView.frame.width * CGFloat(webView.pageCount-1), y: webView.frame.height - lastPageHeight, width: webView.frame.width, height: lastPageHeight)
            colorView.frame = CGRect.zero
        } else {
            colorView.frame = CGRect.zero
        }
    }
    
    // MARK: - Class based click listener
    
    fileprivate func setupClassBasedOnClickListeners() {
        for listener in self.readerConfig.classBasedOnClickListeners {
            self.webView?.js("addClassBasedOnClickListener(\"\(listener.schemeName)\", \"\(listener.querySelector)\", \"\(listener.attributeName)\", \"\(listener.selectAll)\")")
        }
    }
    
    // MARK: - Deadzone Pan Gesture
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == panDeadZoneTop || gestureRecognizer.view == panDeadZoneBot {
            return true
        }
        return false
    }
    
}

//
//  FolioReaderCenter.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 08/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import ZFDragableModalTransition
import WebKit

/// Protocol which is used from `FolioReaderCenter`s.
@objc public protocol FolioReaderCenterDelegate: class {

    /// Notifies that a page appeared. This is triggered when a page is chosen and displayed.
    ///
    /// - Parameter page: The appeared page
    @objc optional func pageDidAppear(_ page: FolioReaderPage)

    /// Passes and returns the HTML content as `String`. Implement this method if you want to modify the HTML content of a `FolioReaderPage`.
    ///
    /// - Parameters:
    ///   - page: The `FolioReaderPage`.
    ///   - htmlContent: The current HTML content as `String`.
    /// - Returns: The adjusted HTML content as `String`. This is the content which will be loaded into the given `FolioReaderPage`.
    @objc func htmlContentForPage(_ page: FolioReaderPage, htmlContent: String) -> String
    
    /// Notifies that a page changed. This is triggered when collection view cell is changed.
    ///
    /// - Parameter pageNumber: The appeared page item
    @objc optional func pageItemChanged(_ pageNumber: Int)

}

/// The base reader class
open class FolioReaderCenter: UIViewController, /*UICollectionViewDelegate,*/ UICollectionViewDataSource
                              /*, UICollectionViewDelegateFlowLayout*/ {

    /// This delegate receives the events from the current `FolioReaderPage`s delegate.
    open var delegate: FolioReaderCenterDelegate?

    /// This delegate receives the events from current page
    open weak var pageDelegate: FolioReaderPageDelegate?

    /// The base reader container
    open weak var readerContainer: FolioReaderContainer?

    /// The current visible page on reader
    open fileprivate(set) var currentPage: FolioReaderPage?

    /// The collection view with pages
    open var collectionView: UICollectionView!
    
    let collectionViewLayout = FolioReaderCenterLayout()
    var loadingView: UIActivityIndicatorView!
    var pages: [String]!
    var totalPages: Int = 0
    var tempFragment: String?
    var animator: ZFModalTransitionAnimator!
    var pageIndicatorView: FolioReaderPageIndicator?
    var pageIndicatorHeight: CGFloat = 20
    var recentlyScrolled = false
    var recentlyScrolledDelay = 2.0 // 2 second delay until we clear recentlyScrolled
    var recentlyScrolledTimer: Timer!
    var scrollScrubber: ScrollScrubber?
    var activityIndicator = UIActivityIndicatorView()
    var isScrolling = false
    var pageScrollDirection = ScrollDirection()
    var nextPageNumber: Int = 0
    var previousPageNumber: Int = 0
    var currentPageNumber: Int = 0
    var pageWidth: CGFloat = 0.0
    var pageHeight: CGFloat = 0.0
    var layoutAdapting = false
    var lastMenuSelectedIndex = 0

    fileprivate var screenBounds: CGRect!
    fileprivate var pointNow = CGPoint.zero
    fileprivate var pageOffsetRate: CGFloat = 0
    fileprivate var tempReference: FRTocReference?
    fileprivate var isFirstLoad = true
    fileprivate var currentWebViewScrollPositions = [Int: CGPoint]()
    fileprivate var currentOrientation: UIInterfaceOrientation?

    // open var userFonts = [String: URL]()
    open var userFontDescriptors = [String: CTFontDescriptor]()
    
    open var pageNavigationDisabled = false
    
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

    // MARK: - Init

    init(withContainer readerContainer: FolioReaderContainer) {
        self.readerContainer = readerContainer
        super.init(nibName: nil, bundle: Bundle.frameworkBundle())

        self.initialization()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("This class doesn't support NSCoding.")
    }

    /**
     Common Initialization
     */
    fileprivate func initialization() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        if (self.readerConfig.hideBars == true) {
            self.pageIndicatorHeight = 0
        }
        
        self.totalPages = book.spine.spineReferences.count

        // Loading indicator
        let style: UIActivityIndicatorView.Style = folioReader.isNight(.white, .gray)
        loadingView = UIActivityIndicatorView(style: style)
        loadingView.hidesWhenStopped = true
        loadingView.startAnimating()
        self.view.addSubview(loadingView)
        
        // Load custom fonts
        if let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let fontsDirectory = documentDirectory.appendingPathComponent("Fonts",  isDirectory: true)
            if FileManager.default.fileExists(atPath: fontsDirectory.path),
               let fontsEnumerator = FileManager.default.enumerator(atPath: fontsDirectory.path) {
                while let file = fontsEnumerator.nextObject() as? String {
                    print("FONTDIR \(file)")
                    let fileURL = fontsDirectory.appendingPathComponent(file)
//                    if let data = try? Data(contentsOf: fileURL) {
//                        guard let provider = CGDataProvider(data: data as CFData) else {
//                            continue
//                        }
//
//                        guard let font = CGFont(provider) else {
//                            continue
//                        }
//
//                        guard let name = font.postScriptName else {
//                            continue
//                        }
//
//                        print("FONTDIR NAME \(name) \(font.italicAngle) \(font)")
//
//                        userFonts[name as String] = fileURL
//
//                        CTFontManagerRegisterFontsForURL(fileURL as CFURL, .process, nil)
//                    }
                    
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
            }
        }
    }

    // MARK: - View life cicle

    override open func viewDidLoad() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }
        
        super.viewDidLoad()

        screenBounds = self.getScreenBounds()
        
        setPageSize(UIApplication.shared.statusBarOrientation)

        // Layout
        collectionViewLayout.sectionInset = UIEdgeInsets.zero
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.scrollDirection = .direction(withConfiguration: self.readerConfig)
        
        //let background = folioReader.isNight(self.readerConfig.nightModeBackground, UIColor.white)
        let background = self.readerConfig.themeModeBackground[folioReader.themeMode]
        view.backgroundColor = background

        // CollectionView
        collectionView = UICollectionView(frame: screenBounds, collectionViewLayout: collectionViewLayout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = background
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        enableScrollBetweenChapters(scrollEnabled: true)
        if readerConfig.debug.contains(.borderHighlight) {
            collectionView.layer.borderWidth = 8
            collectionView.layer.borderColor = UIColor.purple.cgColor
        }
        view.addSubview(collectionView)
        
        // Activity Indicator
        self.activityIndicator.style = .gray
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator = UIActivityIndicatorView(frame: CGRect(x: screenBounds.size.width/2, y: screenBounds.size.height/2, width: 30, height: 30))
        self.activityIndicator.backgroundColor = UIColor.gray
        self.view.addSubview(self.activityIndicator)
        self.view.bringSubviewToFront(self.activityIndicator)

        if #available(iOS 10.0, *) {
            collectionView.isPrefetchingEnabled = false
        }

        // Register cell classes
        collectionView?.register(FolioReaderPage.self, forCellWithReuseIdentifier: kReuseCellIdentifier)

        // Configure navigation bar and layout
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        extendedLayoutIncludesOpaqueBars = true
        configureNavBar()

        // Page indicator view
        if (self.readerConfig.hidePageIndicator == false) {
            let frame = self.frameForPageIndicatorView()
            pageIndicatorView = FolioReaderPageIndicator(frame: frame, readerConfig: readerConfig, folioReader: folioReader)
            if let pageIndicatorView = pageIndicatorView {
                view.addSubview(pageIndicatorView)
            }
        }

        guard let readerContainer = readerContainer else { return }
        self.scrollScrubber = ScrollScrubber(frame: frameForScrollScrubber(), withReaderContainer: readerContainer)
        self.scrollScrubber?.delegate = self
        if let scrollScrubber = scrollScrubber {
            view.addSubview(scrollScrubber.slider)
        }
    }

    override open func viewWillAppear(_ animated: Bool) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        super.viewWillAppear(animated)

        configureNavBar()

        // Update pages
        pagesForCurrentPage(currentPage)
        pageIndicatorView?.reloadView(updateShadow: true)
    }

    override open func viewWillDisappear(_ animated: Bool) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        folioReader.saveReaderState()
    }
    
    override open func viewDidLayoutSubviews() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        super.viewDidLayoutSubviews()

        screenBounds = self.getScreenBounds()
        loadingView.center = view.center

        setPageSize(UIApplication.shared.statusBarOrientation)
        updateSubviewFrames()
    }

    // MARK: Layout

    /**
     Enable or disable the scrolling between chapters (`FolioReaderPage`s). If this is enabled it's only possible to read the current chapter. If another chapter should be displayed is has to be triggered programmatically with `changePageWith`.

     - parameter scrollEnabled: `Bool` which enables or disables the scrolling between `FolioReaderPage`s.
     */
    open func enableScrollBetweenChapters(scrollEnabled: Bool) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        self.collectionView.isScrollEnabled = scrollEnabled
    }

    fileprivate func updateSubviewFrames() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        self.pageIndicatorView?.frame = self.frameForPageIndicatorView()
        self.scrollScrubber?.frame = self.frameForScrollScrubber()
    }

    fileprivate func frameForPageIndicatorView() -> CGRect {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var bounds = CGRect(x: 0, y: screenBounds.size.height-pageIndicatorHeight, width: screenBounds.size.width, height: pageIndicatorHeight)
        
        if #available(iOS 11.0, *) {
            bounds.size.height = bounds.size.height + view.safeAreaInsets.bottom
        }
        
        return bounds
    }

    fileprivate func frameForScrollScrubber() -> CGRect {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let scrubberY: CGFloat = ((self.readerConfig.shouldHideNavigationOnTap == true || self.readerConfig.hideBars == true) ? 50 : 74)
        return CGRect(x: self.pageWidth + 10, y: scrubberY, width: 40, height: (self.pageHeight - 100))
    }

    func configureNavBar() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        //let navBackground = folioReader.isNight(self.readerConfig.nightModeNavBackground, self.readerConfig.daysModeNavBackground)
        let navBackground = self.readerConfig.themeModeNavBackground[folioReader.themeMode]
        let tintColor = readerConfig.tintColor
        let navText = folioReader.isNight(UIColor.white, UIColor.black)
        let font = UIFont(name: "Avenir-Light", size: 17)!
        setTranslucentNavigation(color: navBackground, tintColor: tintColor, titleColor: navText, andFont: font)
    }

    func configureNavBarButtons() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }


        // Navbar buttons
        let shareIcon = UIImage(readerImageNamed: "icon-navbar-share")?.ignoreSystemTint(withConfiguration: self.readerConfig)
        let audioIcon = UIImage(readerImageNamed: "icon-navbar-tts")?.ignoreSystemTint(withConfiguration: self.readerConfig) //man-speech-icon
        let closeIcon = UIImage(readerImageNamed: "icon-navbar-close")?.ignoreSystemTint(withConfiguration: self.readerConfig)
        let tocIcon = UIImage(readerImageNamed: "icon-navbar-toc")?.ignoreSystemTint(withConfiguration: self.readerConfig)
        let fontIcon = UIImage(readerImageNamed: "icon-navbar-font")?.ignoreSystemTint(withConfiguration: self.readerConfig)
        let logoIcon = UIImage(readerImageNamed: "icon-logo")?.ignoreSystemTint(withConfiguration: self.readerConfig)
        let space = 70 as CGFloat

        let menu = UIBarButtonItem(image: closeIcon, style: .plain, target: self, action:#selector(closeReader(_:)))
        let toc = UIBarButtonItem(image: tocIcon, style: .plain, target: self, action:#selector(presentChapterList(_:)))
        let lrp = UIBarButtonItem(image: logoIcon, style: .plain, target: self, action: #selector(gotoLastReadPosition(_:)))

        navigationItem.leftBarButtonItems = [menu, toc, lrp]

        var rightBarIcons = [UIBarButtonItem]()

        if (self.readerConfig.allowSharing == true) {
            rightBarIcons.append(UIBarButtonItem(image: shareIcon, style: .plain, target: self, action:#selector(shareChapter(_:))))
        }

        if self.book.hasAudio || self.readerConfig.enableTTS {
            rightBarIcons.append(UIBarButtonItem(image: audioIcon, style: .plain, target: self, action:#selector(presentPlayerMenu(_:))))
        }

        let font = UIBarButtonItem(image: fontIcon, style: .plain, target: self, action: #selector(presentFontsMenu))
        font.width = space

        rightBarIcons.append(contentsOf: [font])
        navigationItem.rightBarButtonItems = rightBarIcons
        
        if (self.readerConfig.displayTitle) {
            navigationItem.title = book.title
        }
        
    }

    func reloadData() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        self.loadingView.stopAnimating()
        self.totalPages = book.spine.spineReferences.count

        self.collectionView.reloadData()
        self.configureNavBarButtons()
        self.setCollectionViewProgressiveDirection()

        if self.readerConfig.loadSavedPositionForCurrentBook {
            guard let position = folioReader.savedPositionForCurrentBook, let pageNumber = position["pageNumber"] as? Int, pageNumber > 0 else {
//            guard let position = self.readerConfig.savedPositionForCurrentBook, let pageNumber = position["pageNumber"] as? Int, pageNumber > 0 else {
                self.currentPageNumber = 1
                return
            }

            self.changePageWith(page: pageNumber)
            self.currentPageNumber = pageNumber
        }
    }

    // MARK: Change page progressive direction

    private func transformViewForRTL(_ view: UIView?) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        if folioReader.needsRTLChange {
            view?.transform = CGAffineTransform(scaleX: -1, y: 1)
        } else {
            view?.transform = CGAffineTransform.identity
        }
    }

    func setCollectionViewProgressiveDirection() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        self.transformViewForRTL(self.collectionView)
    }

    func setPageProgressiveDirection(_ page: FolioReaderPage) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        self.transformViewForRTL(page)
    }

    // MARK: Change layout orientation

    /// Get internal page offset before layout change
    private func updatePageOffsetRate() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard let currentPage = self.currentPage, let webView = currentPage.webView else {
            return
        }

        let pageScrollView = webView.scrollView
        let contentSize = pageScrollView.contentSize.forDirection(withConfiguration: self.readerConfig)
        let contentOffset = pageScrollView.contentOffset.forDirection(withConfiguration: self.readerConfig)
        self.pageOffsetRate = (contentSize != 0 ? (contentOffset / contentSize) : 0)
    }

    func setScrollDirection(_ direction: FolioReaderScrollDirection) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard let currentPage = self.currentPage, let webView = currentPage.webView else {
            return
        }

        let pageScrollView = webView.scrollView

        // Get internal page offset before layout change
        self.updatePageOffsetRate()
        // Change layout
        self.readerConfig.scrollDirection = direction
        self.collectionViewLayout.scrollDirection = .direction(withConfiguration: self.readerConfig)
        self.currentPage?.setNeedsLayout()
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.setContentOffset(frameForPage(self.currentPageNumber).origin, animated: false)

        // Page progressive direction
        self.setCollectionViewProgressiveDirection()
        delay(0.2) { self.setPageProgressiveDirection(currentPage) }


        /**
         *  This delay is needed because the page will not be ready yet
         *  so the delay wait until layout finished the changes.
         */
        delay(0.1) {
            var pageOffset = (pageScrollView.contentSize.forDirection(withConfiguration: self.readerConfig) * self.pageOffsetRate)

            // Fix the offset for paged scroll
            if (self.readerConfig.scrollDirection == .horizontal && self.pageWidth != 0) {
                let page = round(pageOffset / self.pageWidth)
                pageOffset = (page * self.pageWidth)
            }

            let pageOffsetPoint = self.readerConfig.isDirection(CGPoint(x: 0, y: pageOffset), CGPoint(x: pageOffset, y: 0), CGPoint(x: 0, y: pageOffset))
            pageScrollView.setContentOffset(pageOffsetPoint, animated: true)
        }
    }

    func updateScrollPosition(delay bySecond: Double = 0.1, completion: (() -> Void)?) {
        guard let currentPage = currentPage else { return }
        // After rotation fix internal page offset
        
        self.updatePageOffsetRate()
        delay(bySecond) {
            var pageOffset = (currentPage.webView?.scrollView.contentSize.forDirection(withConfiguration: self.readerConfig) ?? 0) * self.pageOffsetRate

            // Fix the offset for paged scroll
            if (self.readerConfig.scrollDirection == .horizontal && self.pageWidth != 0) {
                let page = round(pageOffset / self.pageWidth)
                pageOffset = page * self.pageWidth
            }

            let pageOffsetPoint = self.readerConfig.isDirection(CGPoint(x: 0, y: pageOffset), CGPoint(x: pageOffset, y: 0), CGPoint(x: 0, y: pageOffset))
            currentPage.webView?.scrollView.setContentOffset(pageOffsetPoint, animated: true)
            
            self.updatePageOffsetRate()
            completion?()
        }
    }
    // MARK: Status bar and Navigation bar

    func hideBars() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard self.readerConfig.shouldHideNavigationOnTap == true else {
            return
        }

        self.updateBarsStatus(true)
    }

    func showBars() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        self.configureNavBar()
        self.updateBarsStatus(false)
    }

    func toggleBars() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard self.readerConfig.shouldHideNavigationOnTap == true else {
            return
        }

        let shouldHide = !self.navigationController!.isNavigationBarHidden
        if shouldHide == false {
            self.configureNavBar()
        }

        self.updateBarsStatus(shouldHide)
    }

    private func updateBarsStatus(_ shouldHide: Bool, shouldShowIndicator: Bool = false) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard let readerContainer = readerContainer else { return }
        readerContainer.shouldHideStatusBar = shouldHide

        UIView.animate(withDuration: 0.25, animations: {
            readerContainer.setNeedsStatusBarAppearanceUpdate()

            // Show minutes indicator
            if (shouldShowIndicator == true) {
                self.pageIndicatorView?.minutesLabel.alpha = shouldHide ? 0 : 1
            }
        })
        self.navigationController?.setNavigationBarHidden(shouldHide, animated: true)
    }

    // MARK: UICollectionViewDataSource

    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        return totalPages
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let reuseableCell = collectionView.dequeueReusableCell(withReuseIdentifier: kReuseCellIdentifier, for: indexPath) as? FolioReaderPage
        return self.configure(readerPageCell: reuseableCell, atIndexPath: indexPath)
    }

    private func configure(readerPageCell cell: FolioReaderPage?, atIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard let cell = cell, let readerContainer = readerContainer else {
            return UICollectionViewCell()
        }

        guard pageNavigationDisabled == false else {
            return cell
        }
        
        cell.setup(withReaderContainer: readerContainer)
        cell.pageNumber = indexPath.row+1
        cell.webView?.scrollView.delegate = self
        if #available(iOS 11.0, *) {
            cell.webView?.scrollView.contentInsetAdjustmentBehavior = .never
        }
        cell.webView?.setupScrollDirection()
        cell.webView?.frame = cell.webViewFrame()
        cell.delegate = self
        cell.backgroundColor = .clear

        setPageProgressiveDirection(cell)

        // Configure the cell
        let resource = self.book.spine.spineReferences[indexPath.row].resource
        guard var html = try? String(contentsOfFile: resource.fullHref, encoding: String.Encoding.utf8) else {
            return cell
        }
        
        // Inject viewport
        let viewportTag = "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, shrink-to-fit=no\">"
        let initialRuntimeStyleCss = folioReader.generateRuntimeStyle()

        let toInject = """
            \(viewportTag)
            <style id=\"style-folioreader-runtime\" type=\"text/css\">
                \(initialRuntimeStyleCss)
            </style>
        </head>
        """
        html = html.replacingOccurrences(of: "</head>", with: toInject)

        // Font class name
        var classes = ""
//        folioReader.currentFont
        classes += " " + folioReader.currentMediaOverlayStyle.className()

        // Night mode
        if folioReader.nightMode {
            classes += " nightMode"
        }
        switch folioReader.themeMode {
        case 1:
            classes += " serpiaMode"
            break
        case 2:
            classes += " greenMode"
            break
        case 3:
            classes += " darkMode"
            break
        default:
            break
        }

        // Font Size
//        classes += " \(folioReader.currentFontSize.cssIdentifier)"

        // TODO block layout
        classes += " justifiedBlockMode"
        
        html = html.replacingOccurrences(of: "<html ", with: "<html class=\"\(classes)\"")

        // Let the delegate adjust the html string
        if let modifiedHtmlContent = self.delegate?.htmlContentForPage(cell, htmlContent: html) {
            html = modifiedHtmlContent
        }
        
        if let resourceBasePath = self.book.smils.basePath {
            
            let contentURL = URL(fileURLWithPath: resource.fullHref)
            print("CONFIG \(cell.debugDescription) \(cell.webView.debugDescription) \(contentURL) \(resourceBasePath)")
            cell.loadFileURLOnceOnly(contentURL, allowingReadAccessTo: URL(fileURLWithPath: resourceBasePath))
        }
        
        cell.loadHTMLString(html, baseURL: URL(fileURLWithPath: resource.fullHref.deletingLastPathComponent))
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var size = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        
        if #available(iOS 11.0, *) {
            let orientation = UIDevice.current.orientation
            
            if orientation == .portrait || orientation == .portraitUpsideDown {
                if readerConfig.scrollDirection == .horizontal {
                    size.height = size.height - view.safeAreaInsets.bottom
                }
            }
        }
        
        return size
    }
    
    // MARK: - View Transition
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        pageNavigationDisabled = false
        
        super.viewWillTransition(to: size, with: coordinator)
        
        if readerConfig.debug.contains(.htmlStyling) {
            print("BEGINTRANSROTATE fromBounds=\(collectionView.bounds) fromContentSize=\(collectionView.contentSize) fromItemSize=\(collectionViewLayout.itemSize) to=\(size) \(String(describing: coordinator.debugDescription))")
        }
        
        guard folioReader.isReaderReady else { return }

        if readerConfig.debug.contains(.htmlStyling) {
            self.collectionView.indexPathsForVisibleItems.forEach {
                print("BEGIN2TRANSROTATE \($0.debugDescription)")
            }
        }
        
        let itemSize = CGSize(
            width: size.width,
            height: size.height - UIApplication.shared.statusBarFrame.height - 20)
        self.collectionViewLayout.itemSize = itemSize
        self.collectionView.setContentOffset(
            CGPoint(x: CGFloat(self.currentPageNumber-1) * itemSize.width,
                    y: 0),
            animated: false)
        self.collectionViewLayout.invalidateLayout()
        
        if readerConfig.debug.contains(.htmlStyling) {
            print("WILLTRANSROTATE \(self.currentPageNumber) \(self.collectionViewLayout.itemSize)")
            self.collectionView.indexPathsForVisibleItems.forEach {
                print("BEGIN3TRANSROTATE \($0.debugDescription)")
            }
        }
        
        setPageSize(UIApplication.shared.statusBarOrientation)

        updateCurrentPage()
        guard let currentPage = self.currentPage else {
            return
        }
        
        if readerConfig.debug.contains(.htmlStyling) {
            print("WILLTRANS2ROTATE \(self.currentPageNumber) \(self.collectionViewLayout.itemSize) \(currentPage.pageNumber!)")
            self.collectionView.indexPathsForVisibleItems.forEach {
                print("BEGIN3TRANSROTATE \($0.debugDescription)")
            }
        }
        
        var pageIndicatorFrame = pageIndicatorView?.frame
        var scrollScrubberFrame = scrollScrubber?.slider.frame
        if self.currentOrientation == nil || (self.currentOrientation?.isPortrait != UIDevice.current.orientation.isPortrait) {
            
            pageIndicatorFrame?.origin.y = ((screenBounds.size.height < screenBounds.size.width) ? (self.collectionView.frame.height - pageIndicatorHeight) : (self.collectionView.frame.width - pageIndicatorHeight))
            pageIndicatorFrame?.origin.x = 0
            pageIndicatorFrame?.size.width = ((screenBounds.size.height < screenBounds.size.width) ? (self.collectionView.frame.width) : (self.collectionView.frame.height))
            pageIndicatorFrame?.size.height = pageIndicatorHeight

            
            scrollScrubberFrame?.origin.x = ((screenBounds.size.height < screenBounds.size.width) ? (screenBounds.size.width - 100) : (screenBounds.size.height + 10))
            scrollScrubberFrame?.size.height = ((screenBounds.size.height < screenBounds.size.width) ? (self.collectionView.frame.height - 100) : (self.collectionView.frame.width - 100))

//            self.collectionView.collectionViewLayout.invalidateLayout()
        }

        if readerConfig.debug.contains(.htmlStyling) {
            print("WILLTRANS3ROTATE \(self.currentPageNumber) \(self.collectionViewLayout.itemSize) \(currentPage.pageNumber ?? -1)")
            self.collectionView.indexPathsForVisibleItems.forEach {
                print("BEGIN3TRANSROTATE \($0.debugDescription)")
            }
        }
        
//        let itemSize = CGSize(width: size.width, height: size.height - UIApplication.shared.statusBarFrame.height)
        self.collectionViewLayout.itemSize = itemSize
        self.collectionView.setContentOffset(
            CGPoint(x: CGFloat(self.currentPageNumber-1) * self.collectionViewLayout.itemSize.width,
                    y: 0),
            animated: false)
        self.collectionViewLayout.invalidateLayout()
        
        if readerConfig.debug.contains(.htmlStyling) {
            print("WILLTRANS4ROTATE \(self.currentPageNumber) \(self.collectionViewLayout.itemSize) \(currentPage.pageNumber!)")
            self.collectionView.indexPathsForVisibleItems.forEach {
                print("BEGIN3TRANSROTATE \($0.debugDescription)")
            }
        }
        
        switch(UIDevice.current.orientation) {
        case .landscapeLeft:
            self.currentOrientation = .landscapeLeft
            break;
        case .landscapeRight:
            self.currentOrientation = .landscapeRight
            break;
        case .portrait:
            self.currentOrientation = .portrait
            break;
        case .portraitUpsideDown:
            self.currentOrientation = .portraitUpsideDown
            break;
        default:
            self.currentOrientation = .unknown
            break
        }
        
        if readerConfig.debug.contains(.htmlStyling) {
            print("BEFOREANIMATIONTRANSROTATE fromBounds=\(self.collectionView.bounds) fromContentSize=\(self.collectionView.contentSize) fromItemSize=\(self.collectionViewLayout.itemSize) offset=\(self.collectionView.contentOffset) to=\(size)")
        }
        coordinator.animate { _ in
            if let pageIndicatorFrame = pageIndicatorFrame {
                self.pageIndicatorView?.frame = pageIndicatorFrame
                self.pageIndicatorView?.reloadView(updateShadow: true)
            }

            // Adjust scroll scrubber slider
            if let scrollScrubberFrame = scrollScrubberFrame {
                self.scrollScrubber?.slider.frame = scrollScrubberFrame
            }

            // Adjust collectionView
            // MARK: TODO
//                self.collectionView.contentSize = self.readerConfig.isDirection(
//                    CGSize(width: self.pageWidth, height: self.pageHeight * CGFloat(self.totalPages)),
//                    CGSize(width: self.pageWidth * CGFloat(self.totalPages), height: self.pageHeight),
//                    CGSize(width: self.pageWidth * CGFloat(self.totalPages), height: self.pageHeight)
//                )
//
//            self.collectionView.setContentOffset(self.frameForPage(self.currentPageNumber).origin, animated: false)
//            self.collectionView.collectionViewLayout.invalidateLayout()

            // Adjust internal page offset
            self.updatePageOffsetRate()
            self.collectionView.setContentOffset(
                CGPoint(x: CGFloat(self.currentPageNumber-1) * self.collectionViewLayout.itemSize.width,
                        y: 0),
                animated: false)
            self.collectionView.collectionViewLayout.invalidateLayout()
            
            
        } completion: { _ in
            if self.readerConfig.debug.contains(.htmlStyling) {
                print("AFTERANIMATIONTRANSROTATE bounds=\(self.collectionView.bounds) contentSize=\(self.collectionView.contentSize) itemSize=\(self.collectionViewLayout.itemSize) offset=\(self.collectionView.contentOffset) to=\(size)")
            }
            
            
            let frameForCurrentPage = self.frameForPage(self.currentPageNumber)
            self.collectionView.scrollRectToVisible(frameForCurrentPage, animated: false)
            
            if self.readerConfig.debug.contains(.htmlStyling) {
                print("AFTERANIMATION2TRANSROTATE bounds=\(self.collectionView.bounds) contentSize=\(self.collectionView.contentSize) itemSize=\(self.collectionViewLayout.itemSize) offset=\(self.collectionView.contentOffset) frameForCurrentPage=\(frameForCurrentPage)")
            }
            
            //DID
            if self.readerConfig.debug.contains(.htmlStyling) {
                print("DIDTRANSROTATE \(self.currentPageNumber) \(self.collectionViewLayout.itemSize) \(currentPage.pageNumber!)")
                self.collectionView.indexPathsForVisibleItems.forEach {
                    print("DIDTRANSROTATE \($0.debugDescription)")
                }
            }
            
//            self.collectionView.setContentOffset(
//                CGPoint(x: CGFloat(self.currentPageNumber-1) * self.collectionViewLayout.itemSize.width,
//                        y: 0),
//                animated: false)
//            self.collectionView.collectionViewLayout.invalidateLayout()
            
            self.setPageSize(UIDevice.current.orientation)
            
            if self.readerConfig.debug.contains(.htmlStyling) {
                print("DID2TRANSROTATE \(self.currentPageNumber) \(self.collectionViewLayout.itemSize) \(currentPage.pageNumber!)")
                self.collectionView.indexPathsForVisibleItems.forEach {
                    print("DID2TRANSROTATE \($0.debugDescription)")
                }
            }
            
            self.updateCurrentPage(currentPage)
            
            if self.readerConfig.debug.contains(.htmlStyling) {
                print("DID3TRANSROTATE \(self.currentPageNumber) \(self.collectionViewLayout.itemSize) \(currentPage.pageNumber!)")
                self.collectionView.indexPathsForVisibleItems.forEach {
                    print("DID3TRANSROTATE \($0.debugDescription)")
                }
            }
            
            // Update pages
            self.pagesForCurrentPage(currentPage)
            currentPage.refreshPageMode()

            self.scrollScrubber?.setSliderVal()

            // After rotation fix internal page offset
            var pageOffset = (currentPage.webView?.scrollView.contentSize.forDirection(withConfiguration: self.readerConfig) ?? 0) * self.pageOffsetRate

            // Fix the offset for paged scroll
            if (self.readerConfig.scrollDirection == .horizontal && self.pageWidth != 0) {
                let page = round(pageOffset / self.pageWidth)
                pageOffset = page * self.pageWidth
            }

            let pageOffsetPoint = self.readerConfig.isDirection(CGPoint(x: 0, y: pageOffset), CGPoint(x: pageOffset, y: 0), CGPoint(x: 0, y: pageOffset))
            currentPage.webView?.scrollView.setContentOffset(pageOffsetPoint, animated: true)
            
            self.updatePageOffsetRate()
            
            if self.readerConfig.debug.contains(.htmlStyling) {
                print("DID4TRANSROTATE \(self.currentPageNumber) \(self.collectionViewLayout.itemSize) \(currentPage.pageNumber!)")
                self.collectionView.indexPathsForVisibleItems.forEach {
                    print("DID4TRANSROTATE \($0.debugDescription)")
                }
            }
            
            self.pageNavigationDisabled = false
        }

    }

//    override open func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
//        guard folioReader.isReaderReady else {
//            return
//        }
//
//        self.collectionView.scrollToItem(at: IndexPath(row: self.currentPageNumber - 1, section: 0), at: UICollectionView.ScrollPosition(), animated: false)
//        if (self.currentPageNumber + 1) >= totalPages {
//            UIView.animate(withDuration: duration, animations: {
//                self.collectionView.setContentOffset(self.frameForPage(self.currentPageNumber).origin, animated: false)
//            })
//        }
//    }

    // MARK: - Page
    @available(iOS, deprecated: 13.0)
    func setPageSize(_ orientation: UIInterfaceOrientation) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }
        if #available(iOS 13.0, *) {
            setPageSize()
            return
        }
        
        guard orientation.isPortrait else {
            if screenBounds.size.width > screenBounds.size.height {
                self.pageWidth = screenBounds.size.width
                self.pageHeight = screenBounds.size.height
            } else {
                self.pageWidth = screenBounds.size.height
                self.pageHeight = screenBounds.size.width
            }
            return
        }

        if screenBounds.size.width < screenBounds.size.height {
            self.pageWidth = screenBounds.size.width
            self.pageHeight = screenBounds.size.height
        } else {
            self.pageWidth = screenBounds.size.height
            self.pageHeight = screenBounds.size.width
        }
    }
    
    @available(iOS, deprecated: 13.0)
    func setPageSize(_ orientation: UIDeviceOrientation) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }
        if #available(iOS 13.0, *) {
            setPageSize()
            return
        }
        guard orientation.isPortrait else {
            if screenBounds.size.width > screenBounds.size.height {
                self.pageWidth = screenBounds.size.width
                self.pageHeight = screenBounds.size.height
            } else {
                self.pageWidth = screenBounds.size.height
                self.pageHeight = screenBounds.size.width
            }
            return
        }

        if screenBounds.size.width < screenBounds.size.height {
            self.pageWidth = screenBounds.size.width
            self.pageHeight = screenBounds.size.height
        } else {
            self.pageWidth = screenBounds.size.height
            self.pageHeight = screenBounds.size.width
        }
    }
    
    func setPageSize() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        self.pageWidth = screenBounds.size.width
        self.pageHeight = screenBounds.size.height
    }

    func updateCurrentPage(_ page: FolioReaderPage? = nil, completion: (() -> Void)? = nil) {
        if readerConfig.debug.contains(.functionTrace) {
            folioLogger("ENTER");
            Thread.callStackSymbols.forEach{print($0)}
        }

        if let page = page {
            currentPage = page
            self.previousPageNumber = page.pageNumber-1
            self.currentPageNumber = page.pageNumber
        } else {
            let currentIndexPath = getCurrentIndexPath()
            currentPage = collectionView.cellForItem(at: currentIndexPath) as? FolioReaderPage

            self.previousPageNumber = currentIndexPath.row
            self.currentPageNumber = currentIndexPath.row+1
        }

        self.nextPageNumber = (((self.currentPageNumber + 1) <= totalPages) ? (self.currentPageNumber + 1) : self.currentPageNumber)

        // Set pages
        guard let currentPage = currentPage else {
            completion?()
            return
        }

        scrollScrubber?.setSliderVal()
        currentPage.webView?.js("getReadingTime()") { readingTime in
            self.pageIndicatorView?.totalMinutes = Int(readingTime ?? "0")!
            self.pagesForCurrentPage(currentPage)
            self.delegate?.pageDidAppear?(currentPage)
            self.delegate?.pageItemChanged?(self.getCurrentPageItemNumber())
            completion?()
        }
    }

    func pagesForCurrentPage(_ page: FolioReaderPage?) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard let page = page, let webView = page.webView else { return }

        let pageSize = self.readerConfig.isDirection(pageHeight, self.pageWidth, pageHeight)
        let contentSize = page.webView?.scrollView.contentSize.forDirection(withConfiguration: self.readerConfig) ?? 0
        self.pageIndicatorView?.totalPages = ((pageSize != 0) ? Int(ceil(contentSize / pageSize)) : 0)

        let pageOffSet = self.readerConfig.isDirection(webView.scrollView.contentOffset.x, webView.scrollView.contentOffset.x, webView.scrollView.contentOffset.y)
        let webViewPage = pageForOffset(pageOffSet, pageHeight: pageSize)

        self.pageIndicatorView?.currentPage = webViewPage
    }

    func pageForOffset(_ offset: CGFloat, pageHeight height: CGFloat) -> Int {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard (height != 0) else {
            return 0
        }

        let page = Int(ceil(offset / height))+1
        return page
    }

    func getCurrentIndexPath() -> IndexPath {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let indexPaths = collectionView.indexPathsForVisibleItems
        var indexPath = IndexPath()

        if indexPaths.count > 1 {
            let first = indexPaths.first!
            let last = indexPaths.last!

            switch self.pageScrollDirection {
            case .up, .left:
                if first.compare(last) == .orderedAscending {
                    indexPath = last
                } else {
                    indexPath = first
                }
            default:
                if first.compare(last) == .orderedAscending {
                    indexPath = first
                } else {
                    indexPath = last
                }
            }
        } else {
            indexPath = indexPaths.first ?? IndexPath(row: 0, section: 0)
        }

        return indexPath
    }

    func frameForPage(_ page: Int) -> CGRect {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        return self.readerConfig.isDirection(
            CGRect(x: 0, y: self.pageHeight * CGFloat(page-1), width: self.pageWidth, height: self.pageHeight),
            CGRect(x: self.pageWidth * CGFloat(page-1), y: 0, width: self.pageWidth, height: self.pageHeight),
            CGRect(x: 0, y: self.pageHeight * CGFloat(page-1), width: self.pageWidth, height: self.pageHeight)
        )
    }

    open func changePageWith(page: Int, andFragment fragment: String, animated: Bool = false, completion: (() -> Void)? = nil) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        if (self.currentPageNumber == page) {
            if let currentPage = currentPage , fragment != "" {
                currentPage.handleAnchor(fragment, avoidBeginningAnchors: true, animated: animated)
            }
            completion?()
        } else {
            tempFragment = fragment
            changePageWith(page: page, animated: animated, completion: { () -> Void in
                self.updateCurrentPage {
                    completion?()
                }
            })
        }
    }

    open func changePageWith(href: String, animated: Bool = false, completion: (() -> Void)? = nil) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let item = findPageByHref(href)
        let indexPath = IndexPath(row: item, section: 0)
        changePageWith(indexPath: indexPath, animated: animated, completion: { () -> Void in
            self.updateCurrentPage {
                completion?()
            }
        })
    }

    open func changePageWith(href: String, andAudioMarkID markID: String) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        if recentlyScrolled { return } // if user recently scrolled, do not change pages or scroll the webview
        guard let currentPage = currentPage else { return }

        let item = findPageByHref(href)
        let pageUpdateNeeded = item+1 != currentPage.pageNumber
        let indexPath = IndexPath(row: item, section: 0)
        changePageWith(indexPath: indexPath, animated: true) { () -> Void in
            if pageUpdateNeeded {
                self.updateCurrentPage {
                    currentPage.audioMarkID(markID)
                }
            } else {
                currentPage.audioMarkID(markID)
            }
        }
    }

    open func changePageWith(indexPath: IndexPath, animated: Bool = false, completion: (() -> Void)? = nil) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard indexPathIsValid(indexPath) else {
            print("ERROR: Attempt to scroll to invalid index path")
            completion?()
            return
        }

        UIView.animate(withDuration: animated ? 0.3 : 0, delay: 0, options: UIView.AnimationOptions(), animations: { () -> Void in
            self.collectionView.scrollToItem(at: indexPath, at: .direction(withConfiguration: self.readerConfig), animated: false)
        }) { (finished: Bool) -> Void in
            completion?()
        }
    }
    
    open func changePageWith(href: String, pageItem: Int, animated: Bool = false, completion: (() -> Void)? = nil) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        changePageWith(href: href, animated: animated) {
            self.changePageItem(to: pageItem)
        }
    }

    func indexPathIsValid(_ indexPath: IndexPath) -> Bool {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let section = indexPath.section
        let row = indexPath.row
        let lastSectionIndex = numberOfSections(in: collectionView) - 1

        //Make sure the specified section exists
        if section > lastSectionIndex {
            return false
        }

        let rowCount = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section) - 1
        return row <= rowCount
    }

    open func isLastPage() -> Bool{
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        return (currentPageNumber == self.nextPageNumber)
    }

    public func changePageToNext(_ completion: (() -> Void)? = nil) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        changePageWith(page: self.nextPageNumber, animated: true) { () -> Void in
            completion?()
        }
    }

    public func changePageToPrevious(_ completion: (() -> Void)? = nil) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        changePageWith(page: self.previousPageNumber, animated: true) { () -> Void in
            completion?()
        }
    }
    
    public func changePageItemToNext(_ completion: (() -> Void)? = nil) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        // TODO: It was implemented for horizontal orientation.
        // Need check page orientation (v/h) and make correct calc for vertical
        guard
            let cell = collectionView.cellForItem(at: getCurrentIndexPath()) as? FolioReaderPage,
            let contentOffset = cell.webView?.scrollView.contentOffset,
            let contentOffsetXLimit = cell.webView?.scrollView.contentSize.width else {
                completion?()
                return
        }
        
        let cellSize = cell.frame.size
        let contentOffsetX = contentOffset.x + cellSize.width
        
        if contentOffsetX >= contentOffsetXLimit {
            changePageToNext(completion)
        } else {
            cell.scrollPageToOffset(contentOffsetX, animated: true)
        }
        
        completion?()
    }

    public func getCurrentPageItemNumber() -> Int {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard let page = currentPage, let webView = page.webView else { return 0 }
        
        let pageSize = readerConfig.isDirection(pageHeight, pageWidth, pageHeight)
        let pageOffSet = readerConfig.isDirection(webView.scrollView.contentOffset.y, webView.scrollView.contentOffset.x, webView.scrollView.contentOffset.y)
        let webViewPage = pageForOffset(pageOffSet, pageHeight: pageSize)
        
        return webViewPage
    }
    
    public func getCurrentPageProgress() -> Double {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard let page = currentPage else { return 0 }
        
        let pageSize = self.readerConfig.isDirection(pageHeight, self.pageWidth, pageHeight)
        let contentSize = page.webView?.scrollView.contentSize.forDirection(withConfiguration: self.readerConfig) ?? 0
        let totalPages = ((pageSize != 0) ? Int(ceil(contentSize / pageSize)) : 0)
        let currentPageItem = getCurrentPageItemNumber()
        
        if totalPages > 0 {
            var progress = Double(currentPageItem - 1) * 100.0 / Double(totalPages)
            
            if progress < 0 { progress = 0 }
            if progress > 100 { progress = 100 }
            
            return progress
        }
        
        return 0
    }

    public func changePageItemToPrevious(_ completion: (() -> Void)? = nil) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        // TODO: It was implemented for horizontal orientation.
        // Need check page orientation (v/h) and make correct calc for vertical
        guard
            let cell = collectionView.cellForItem(at: getCurrentIndexPath()) as? FolioReaderPage,
            let contentOffset = cell.webView?.scrollView.contentOffset else {
                completion?()
                return
        }
        
        let cellSize = cell.frame.size
        let contentOffsetX = contentOffset.x - cellSize.width
        
        if contentOffsetX < 0 {
            changePageToPrevious(completion)
        } else {
            cell.scrollPageToOffset(contentOffsetX, animated: true)
        }
        
        completion?()
    }

    public func changePageItemToLast(animated: Bool = true, _ completion: (() -> Void)? = nil) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        // TODO: It was implemented for horizontal orientation.
        // Need check page orientation (v/h) and make correct calc for vertical
        guard
            let cell = collectionView.cellForItem(at: getCurrentIndexPath()) as? FolioReaderPage,
            let contentSize = cell.webView?.scrollView.contentSize else {
                completion?()
                return
        }
        
        let cellSize = cell.frame.size
        var contentOffsetX: CGFloat = 0.0
        
        if contentSize.width > 0 && cellSize.width > 0 {
            contentOffsetX = (cellSize.width * (contentSize.width / cellSize.width)) - cellSize.width
        }
        
        if contentOffsetX < 0 {
            contentOffsetX = 0
        }
        
        cell.scrollPageToOffset(contentOffsetX, animated: animated)
        
        completion?()
    }

    public func changePageItem(to: Int, animated: Bool = true, completion: (() -> Void)? = nil) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        // TODO: It was implemented for horizontal orientation.
        // Need check page orientation (v/h) and make correct calc for vertical
        guard
            let cell = collectionView.cellForItem(at: getCurrentIndexPath()) as? FolioReaderPage,
            let contentSize = cell.webView?.scrollView.contentSize else {
                delegate?.pageItemChanged?(getCurrentPageItemNumber())
                completion?()
                return
        }
        
        let cellSize = cell.frame.size
        var contentOffsetX: CGFloat = 0.0
        
        if contentSize.width > 0 && cellSize.width > 0 {
            contentOffsetX = (cellSize.width * CGFloat(to)) - cellSize.width
        }
        
        if contentOffsetX > contentSize.width {
            contentOffsetX = contentSize.width - cellSize.width
        }
        
        if contentOffsetX < 0 {
            contentOffsetX = 0
        }
        
        UIView.animate(withDuration: animated ? 0.3 : 0, delay: 0, options: UIView.AnimationOptions(), animations: { () -> Void in
            cell.scrollPageToOffset(contentOffsetX, animated: animated)
        }) { (finished: Bool) -> Void in
            self.updateCurrentPage {
                completion?()
            }
        }
    }

    /**
     Find a page by FRTocReference.
     */
    public func findPageByResource(_ reference: FRTocReference) -> Int {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var count = 0
        for item in self.book.spine.spineReferences {
            if let resource = reference.resource, item.resource == resource {
                return count
            }
            count += 1
        }
        return count
    }

    /**
     Find a page by href.
     */
    public func findPageByHref(_ href: String) -> Int {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var count = 0
        for item in self.book.spine.spineReferences {
            if item.resource.href == href {
                return count
            }
            count += 1
        }
        return count
    }

    /**
     Find and return the current chapter resource.
     */
    public func getCurrentChapter() -> FRResource? {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var foundResource: FRResource?

        func search(_ items: [FRTocReference]) {
            for item in items {
                guard foundResource == nil else { break }

                if let reference = book.spine.spineReferences[safe: (currentPageNumber - 1)], let resource = item.resource, resource == reference.resource {
                    foundResource = resource
                    break
                } else if let children = item.children, children.isEmpty == false {
                    search(children)
                }
            }
        }
        search(book.flatTableOfContents)

        return foundResource
    }

    /**
     Return the current chapter progress based on current chapter and total of chapters.
     */
    public func getCurrentChapterProgress() -> Double {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let total = totalPages
        let current = currentPageNumber
        
        if total == 0 {
            return 0
        }
        if current == 0 {
            return 0
        }
        
        return 100.0 * Double(current - 1) / Double(total)
    }

    public func getBookProgress() -> Double {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let chapterProgress = getCurrentChapterProgress()
        let pageProgress = getCurrentPageProgress()
        
        let total = totalPages
        
        if total == 0 {
            return 0
        }
        
        return chapterProgress + Double(pageProgress) / Double(total)
    }
    
    /**
     Find and return the current chapter name.
     */
    public func getCurrentChapterName() -> String? {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var foundChapterName: String?
        
        func search(_ items: [FRTocReference]) {
            for item in items {
                guard foundChapterName == nil else { break }
                
                if let reference = self.book.spine.spineReferences[safe: (self.currentPageNumber - 1)],
                    let resource = item.resource,
                    resource == reference.resource,
                    let title = item.title {
                    foundChapterName = title
                } else if let children = item.children, children.isEmpty == false {
                    search(children)
                }
            }
        }
        search(self.book.flatTableOfContents)
        
        return foundChapterName
    }

    // MARK: Public page methods

    /**
     Changes the current page of the reader.

     - parameter page: The target page index. Note: The page index starts at 1 (and not 0).
     - parameter animated: En-/Disables the animation of the page change.
     - parameter completion: A Closure which is called if the page change is completed.
     */
    public func changePageWith(page: Int, animated: Bool = false, completion: (() -> Void)? = nil) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        if page > 0 && page-1 < totalPages {
            let indexPath = IndexPath(row: page-1, section: 0)
            changePageWith(indexPath: indexPath, animated: animated, completion: { () -> Void in
                self.updateCurrentPage {
                    completion?()
                }
            })
        }
    }

    // MARK: - Audio Playing

    func audioMark(href: String, fragmentID: String) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        changePageWith(href: href, andAudioMarkID: fragmentID)
    }

    // MARK: - Sharing

    /**
     Sharing chapter method.
     */
    @objc func shareChapter(_ sender: UIBarButtonItem) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        guard let currentPage = currentPage else { return }

        currentPage.webView?.js("getBodyText()") { chapterText in
            guard let chapterText = chapterText else { return }
            let htmlText = chapterText.replacingOccurrences(of: "[\\n\\r]+", with: "<br />", options: .regularExpression)
            var subject = self.readerConfig.localizedShareChapterSubject
            var html = ""
            var text = ""
            var bookTitle = ""
            var chapterName = ""
            var authorName = ""
            var shareItems = [AnyObject]()

            // Get book title
            if let title = self.book.title {
                bookTitle = title
                subject += " “\(title)”"
            }

            // Get chapter name
            if let chapter = self.getCurrentChapterName() {
                chapterName = chapter
            }

            // Get author name
            if let author = self.book.metadata.creators.first {
                authorName = author.name
            }

            // Sharing html and text
            html = "<html><body>"
            html += "<br /><hr> <p>\(htmlText)</p> <hr><br />"
            html += "<center><p style=\"color:gray\">"+self.readerConfig.localizedShareAllExcerptsFrom+"</p>"
            html += "<b>\(bookTitle)</b><br />"
            html += self.readerConfig.localizedShareBy+" <i>\(authorName)</i><br />"
            
            if let bookShareLink = self.readerConfig.localizedShareWebLink {
                html += "<a href=\"\(bookShareLink.absoluteString)\">\(bookShareLink.absoluteString)</a>"
                shareItems.append(bookShareLink as AnyObject)
            }

            html += "</center></body></html>"
            text = "\(chapterName)\n\n“\(chapterText)” \n\n\(bookTitle) \n\(self.readerConfig.localizedShareBy) \(authorName)"

            let act = FolioReaderSharingProvider(subject: subject, text: text, html: html)
            shareItems.insert(contentsOf: [act, "" as AnyObject], at: 0)

            let activityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            activityViewController.excludedActivityTypes = [UIActivity.ActivityType.print, UIActivity.ActivityType.postToVimeo]

            // Pop style on iPad
            if let actv = activityViewController.popoverPresentationController {
                actv.barButtonItem = sender
            }

           self.present(activityViewController, animated: true, completion: nil)
        }
    }

    /**
     Sharing highlight method.
     */
    func shareHighlight(_ string: String, rect: CGRect) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var subject = readerConfig.localizedShareHighlightSubject
        var html = ""
        var text = ""
        var bookTitle = ""
        var chapterName = ""
        var authorName = ""
        var shareItems = [AnyObject]()

        // Get book title
        if let title = self.book.title {
            bookTitle = title
            subject += " “\(title)”"
        }

        // Get chapter name
        if let chapter = getCurrentChapterName() {
            chapterName = chapter
        }

        // Get author name
        if let author = self.book.metadata.creators.first {
            authorName = author.name
        }

        // Sharing html and text
        html = "<html><body>"
        html += "<br /><hr> <p>\(chapterName)</p>"
        html += "<p>\(string)</p> <hr><br />"
        html += "<center><p style=\"color:gray\">"+readerConfig.localizedShareAllExcerptsFrom+"</p>"
        html += "<b>\(bookTitle)</b><br />"
        html += readerConfig.localizedShareBy+" <i>\(authorName)</i><br />"

        if let bookShareLink = readerConfig.localizedShareWebLink {
            html += "<a href=\"\(bookShareLink.absoluteString)\">\(bookShareLink.absoluteString)</a>"
            shareItems.append(bookShareLink as AnyObject)
        }

        html += "</center></body></html>"
        text = "\(chapterName)\n\n“\(string)” \n\n\(bookTitle) \n\(readerConfig.localizedShareBy) \(authorName)"

        let act = FolioReaderSharingProvider(subject: subject, text: text, html: html)
        shareItems.insert(contentsOf: [act, "" as AnyObject], at: 0)

        let activityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivity.ActivityType.print, UIActivity.ActivityType.postToVimeo]

        // Pop style on iPad
        if let actv = activityViewController.popoverPresentationController {
            actv.sourceView = currentPage
            actv.sourceRect = rect
        }

        present(activityViewController, animated: true, completion: nil)
    }

    // MARK: - ScrollView Delegate

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        self.isScrolling = true
        clearRecentlyScrolled()
        recentlyScrolled = true
        pointNow = scrollView.contentOffset
        
        if (scrollView is UICollectionView) {
            scrollView.isUserInteractionEnabled = false
        }

        if let currentPage = currentPage {
            currentPage.webView?.createMenu(options: true)
            currentPage.webView?.setMenuVisible(false)
        }

        scrollScrubber?.scrollViewWillBeginDragging(scrollView)
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER"); }

        if (navigationController?.isNavigationBarHidden == false) {
            self.toggleBars()
        }

        scrollScrubber?.scrollViewDidScroll(scrollView)

        let isCollectionScrollView = (scrollView is UICollectionView)
        let scrollType: ScrollType = ((isCollectionScrollView == true) ? .chapter : .page)

        // Update current reading page
        if (isCollectionScrollView == false), let page = currentPage, let webView = page.webView {

            let pageSize = self.readerConfig.isDirection(self.pageHeight, self.pageWidth, self.pageHeight)
            let contentOffset = webView.scrollView.contentOffset.forDirection(withConfiguration: self.readerConfig)
            let contentSize = webView.scrollView.contentSize.forDirection(withConfiguration: self.readerConfig)
            if (contentOffset + pageSize <= contentSize) {

                let webViewPage = pageForOffset(contentOffset, pageHeight: pageSize)

                if (readerConfig.scrollDirection == .horizontalWithVerticalContent) {
                    let currentIndexPathRow = (page.pageNumber - 1)

                    // if the cell reload doesn't save the top position offset
                    if let oldOffSet = self.currentWebViewScrollPositions[currentIndexPathRow], (abs(oldOffSet.y - scrollView.contentOffset.y) > 100) {
                        // Do nothing
                    } else {
                        self.currentWebViewScrollPositions[currentIndexPathRow] = scrollView.contentOffset
                    }
                }

                if (pageIndicatorView?.currentPage != webViewPage) {
                    pageIndicatorView?.currentPage = webViewPage
                }
                
                self.delegate?.pageItemChanged?(webViewPage)
            }
        }

        self.updatePageScrollDirection(inScrollView: scrollView, forScrollType: scrollType)
    }

    private func updatePageScrollDirection(inScrollView scrollView: UIScrollView, forScrollType scrollType: ScrollType) {

        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let scrollViewContentOffsetForDirection = scrollView.contentOffset.forDirection(withConfiguration: self.readerConfig, scrollType: scrollType)
        let pointNowForDirection = pointNow.forDirection(withConfiguration: self.readerConfig, scrollType: scrollType)
        // The movement is either positive or negative. This happens if the page change isn't completed. Toggle to the other scroll direction then.
        let isCurrentlyPositive = (self.pageScrollDirection == .left || self.pageScrollDirection == .up)

        if (scrollViewContentOffsetForDirection < pointNowForDirection) {
            self.pageScrollDirection = .negative(withConfiguration: self.readerConfig, scrollType: scrollType)
        } else if (scrollViewContentOffsetForDirection > pointNowForDirection) {
            self.pageScrollDirection = .positive(withConfiguration: self.readerConfig, scrollType: scrollType)
        } else if (isCurrentlyPositive == true) {
            self.pageScrollDirection = .negative(withConfiguration: self.readerConfig, scrollType: scrollType)
        } else {
            self.pageScrollDirection = .positive(withConfiguration: self.readerConfig, scrollType: scrollType)
        }
    }

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        self.isScrolling = false
        
        if (scrollView is UICollectionView) {
            scrollView.isUserInteractionEnabled = true
        }

        // Perform the page after a short delay as the collection view hasn't completed it's transition if this method is called (the index paths aren't right during fast scrolls).
        delay(0.2, closure: { [weak self] in
            if (self?.readerConfig.scrollDirection == .horizontalWithVerticalContent),
                let cell = ((scrollView.superview as? WKWebView)?.navigationDelegate as? FolioReaderPage) {
                let currentIndexPathRow = cell.pageNumber - 1
                self?.currentWebViewScrollPositions[currentIndexPathRow] = scrollView.contentOffset
            }

            if (scrollView is UICollectionView) {
                guard let instance = self else {
                    return
                }
                
                if instance.totalPages > 0 {
                    instance.updateCurrentPage()
                    instance.delegate?.pageItemChanged?(instance.getCurrentPageItemNumber())
                }
            } else {
                self?.scrollScrubber?.scrollViewDidEndDecelerating(scrollView)
            }
        })
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        recentlyScrolledTimer = Timer(timeInterval:recentlyScrolledDelay, target: self, selector: #selector(FolioReaderCenter.clearRecentlyScrolled), userInfo: nil, repeats: false)
        RunLoop.current.add(recentlyScrolledTimer, forMode: RunLoop.Mode.common)
    }

    @objc func clearRecentlyScrolled() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        if(recentlyScrolledTimer != nil) {
            recentlyScrolledTimer.invalidate()
            recentlyScrolledTimer = nil
        }
        recentlyScrolled = false
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        scrollScrubber?.scrollViewDidEndScrollingAnimation(scrollView)
    }

    // MARK: NavigationBar Actions

    @objc func closeReader(_ sender: UIBarButtonItem) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        dismiss()
        folioReader.close()
    }

    /**
     Present chapter list
     */
    @objc func presentChapterList(_ sender: UIBarButtonItem) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        folioReader.saveReaderState()

        let chapter = FolioReaderChapterList(folioReader: folioReader, readerConfig: readerConfig, book: book, delegate: self)
        let highlight = FolioReaderHighlightList(folioReader: folioReader, readerConfig: readerConfig)
        let pageController = PageViewController(folioReader: folioReader, readerConfig: readerConfig)

        pageController.viewControllerOne = chapter
        pageController.viewControllerTwo = highlight
        pageController.segmentedControlItems = [readerConfig.localizedContentsTitle, readerConfig.localizedHighlightsTitle]

        let nav = UINavigationController(rootViewController: pageController)
        present(nav, animated: true, completion: nil)
    }

    @objc func gotoLastReadPosition(_ sender: UIBarButtonItem) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        if self.readerConfig.loadSavedPositionForCurrentBook, let position = self.readerConfig.savedPositionForCurrentBook {
            let pageNumber = position["pageNumber"] as? Int
            let offset = self.readerConfig.isDirection(position["pageOffsetY"], position["pageOffsetX"], position["pageOffsetY"]) as? CGFloat
            let pageOffset = offset

            if (self.currentPageNumber == pageNumber && pageOffset > 0) {
                self.currentPage?.scrollPageToOffset(pageOffset!, animated: false)
            }
        }
    }
    
    /**
     Present fonts and settings menu
     */
    @objc func presentFontsMenu() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        folioReader.saveReaderState()
        hideBars()

        let menuFontTab = FolioReaderFontsMenu(folioReader: folioReader, readerConfig: readerConfig)
        menuFontTab.tabBarItem = .init(title: "Page", image: nil, tag: 0)
        
        let menuFontStyleTab = FolioReaderFontStyleMenu(folioReader: folioReader, readerConfig: readerConfig)
        menuFontStyleTab.tabBarItem = .init(title: "Font", image: nil, tag: 1)
        
        let menuParagraphTab = FolioReaderParagraphMenu(folioReader: folioReader, readerConfig: readerConfig)
        menuParagraphTab.tabBarItem = .init(title: "Paragraph", image: nil, tag: 2)
        
        let menuStructureTab = FolioReaderStructureMenu(folioReader: folioReader, readerConfig: readerConfig)
        menuStructureTab.tabBarItem = .init(title: "Structure", image: nil, tag: 3)
        
        let menu = UITabBarController()
        menu.setViewControllers([menuFontTab, menuFontStyleTab, menuParagraphTab, menuStructureTab], animated: true)
        menu.modalPresentationStyle = .custom
        menu.selectedIndex = lastMenuSelectedIndex

        animator = ZFModalTransitionAnimator(modalViewController: menu)
        animator.isDragable = false
        animator.bounces = false
        animator.behindViewAlpha = 1.0
        animator.behindViewScale = 1.0
        animator.transitionDuration = 0.6
        animator.direction = ZFModalTransitonDirection.bottom

        menu.transitioningDelegate = animator
        self.present(menu, animated: true, completion: nil)
    }

    /**
     Present audio player menu
     */
    @objc func presentPlayerMenu(_ sender: UIBarButtonItem) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        folioReader.saveReaderState()
        hideBars()

        let menu = FolioReaderPlayerMenu(folioReader: folioReader, readerConfig: readerConfig)
        menu.modalPresentationStyle = .custom

        animator = ZFModalTransitionAnimator(modalViewController: menu)
        animator.isDragable = true
        animator.bounces = false
        animator.behindViewAlpha = 0.4
        animator.behindViewScale = 1
        animator.transitionDuration = 0.6
        animator.direction = ZFModalTransitonDirection.bottom

        menu.transitioningDelegate = animator
        present(menu, animated: true, completion: nil)
    }

    /**
     Present Quote Share
     */
    func presentQuoteShare(_ string: String) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let quoteShare = FolioReaderQuoteShare(initWithText: string, readerConfig: readerConfig, folioReader: folioReader, book: book)
        let nav = UINavigationController(rootViewController: quoteShare)

        if UIDevice.current.userInterfaceIdiom == .pad {
            nav.modalPresentationStyle = .formSheet
        }
        present(nav, animated: true, completion: nil)
    }
    
    /**
     Present add highlight note
     */
    func presentAddHighlightNote(_ highlight: Highlight, edit: Bool) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let addHighlightView = FolioReaderAddHighlightNote(withHighlight: highlight, folioReader: folioReader, readerConfig: readerConfig)
        addHighlightView.isEditHighlight = edit
        let nav = UINavigationController(rootViewController: addHighlightView)
        nav.modalPresentationStyle = .formSheet
        
        present(nav, animated: true, completion: nil)
    }
    
    func presentAddHighlightError(_ message: String) {
        let textView = UITextView()
        textView.text = message
        
        let vc = UIViewController()
        vc.view = textView
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            alert.dismiss()
        }))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: FolioPageDelegate

extension FolioReaderCenter: FolioReaderPageDelegate {

    public func pageDidLoad(_ page: FolioReaderPage) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        if self.readerConfig.loadSavedPositionForCurrentBook, let position = folioReader.savedPositionForCurrentBook {
//        if self.readerConfig.loadSavedPositionForCurrentBook, let position = self.readerConfig.savedPositionForCurrentBook {
//            folioReader.savedPositionForCurrentBook = position
            let pageNumber = position["pageNumber"] as? Int
            let offset = self.readerConfig.isDirection(position["pageOffsetY"], position["pageOffsetX"], position["pageOffsetY"]) as? CGFloat
            let pageOffset = offset

            if isFirstLoad {
                updateCurrentPage(page)
                isFirstLoad = false

                if (self.currentPageNumber == pageNumber && pageOffset > 0) {
                    page.scrollPageToOffset(pageOffset!, animated: false)
                }
                
            } else if (self.isScrolling == false && folioReader.needsRTLChange == true) {
                page.scrollPageToBottom()
            }
        } else if isFirstLoad {
            updateCurrentPage(page)
            isFirstLoad = false
        }

        updateCurrentPage(page)
        page.webView?.isHidden = false
        
        // Go to fragment if needed
        if let fragmentID = tempFragment, let currentPage = currentPage , fragmentID != "" {
            currentPage.handleAnchor(fragmentID, avoidBeginningAnchors: true, animated: true)
            tempFragment = nil
        }
        
        if (readerConfig.scrollDirection == .horizontalWithVerticalContent),
            let offsetPoint = self.currentWebViewScrollPositions[page.pageNumber - 1] {
            page.webView?.scrollView.setContentOffset(offsetPoint, animated: false)
        }
        
        // Pass the event to the centers `pageDelegate`
        pageDelegate?.pageDidLoad?(page)
    }
    
    public func pageWillLoad(_ page: FolioReaderPage) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        // Pass the event to the centers `pageDelegate`
        pageDelegate?.pageWillLoad?(page)
    }
    
    public func pageTap(_ recognizer: UITapGestureRecognizer) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        // Pass the event to the centers `pageDelegate`
        pageDelegate?.pageTap?(recognizer)
    }
    
}

// MARK: FolioReaderChapterListDelegate

extension FolioReaderCenter: FolioReaderChapterListDelegate {
    
    func chapterList(_ chapterList: FolioReaderChapterList, didSelectRowAtIndexPath indexPath: IndexPath, withTocReference reference: FRTocReference) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let item = findPageByResource(reference)
        
        if item < totalPages {
            let indexPath = IndexPath(row: item, section: 0)
            changePageWith(indexPath: indexPath, animated: false, completion: { () -> Void in
                self.updateCurrentPage()
            })
            tempReference = reference
        } else {
            print("Failed to load book because the requested resource is missing.")
        }
    }
    
    func chapterList(didDismissedChapterList chapterList: FolioReaderChapterList) {
        updateCurrentPage()
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        // Move to #fragment
        if let reference = tempReference {
            if let fragmentID = reference.fragmentID, let currentPage = currentPage , fragmentID != "" {
                currentPage.handleAnchor(reference.fragmentID!, avoidBeginningAnchors: true, animated: true)
            }
            tempReference = nil
        }
    }
    
    func getScreenBounds() -> CGRect {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var bounds = view.frame
        
        if #available(iOS 11.0, *) {
            bounds.size.height = bounds.size.height - view.safeAreaInsets.bottom
        }
        
        if readerConfig.debug.contains(.borderHighlight) {
            print("getScreenBounds \(bounds) \(UIApplication.shared.statusBarOrientation.rawValue)")
        }
        
        return bounds
    }
    
}

extension FolioReaderCenter: UICollectionViewDelegate {
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }
        if readerConfig.debug.contains(.viewTransition) {
            print("WILLDISPLAYTRANSROTATE \(indexPath)")
        }
    }
}

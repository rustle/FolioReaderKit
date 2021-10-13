//
//  FolioReaderCenter.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 08/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import WebKit
import ZFDragableModalTransition


/// The base reader class
open class FolioReaderCenter: UIViewController {

    /// This delegate receives the events from the current `FolioReaderPage`s delegate.
    open var delegate: FolioReaderCenterDelegate?

    /// This delegate receives the events from current page
    open weak var pageDelegate: FolioReaderPageDelegate?

    /// The base reader container
    open weak var readerContainer: FolioReaderContainer?

    /// The current visible page on reader
    open var currentPage: FolioReaderPage?

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
    var currentPageNumber: Int = 0 {
        didSet {
            print("currentPageNumber \(oldValue) -> \(currentPageNumber)")
        }
    }
    var isLastPage: Bool {
        currentPageNumber == nextPageNumber
    }
    
    var pageWidth: CGFloat = 0.0
    var pageHeight: CGFloat = 0.0
    
    var layoutAdapting = false
    var lastMenuSelectedIndex = 0

    var screenBounds: CGRect!
    var pointNow = CGPoint.zero
    var pageOffsetRate: CGFloat = 0
    var tempReference: FRTocReference?
    var isFirstLoad = true
    var currentWebViewScrollPositions = [Int: CGPoint]()

    var tempCollectionViewInset: CGFloat = 0.0
    
    var menuBarController = UITabBarController()
    var menuTabs = [FolioReaderMenu]()
    
    var readerConfig: FolioReaderConfig {
        guard let readerContainer = readerContainer else { return FolioReaderConfig() }
        return readerContainer.readerConfig
    }

    var book: FRBook {
        guard let readerContainer = readerContainer else { return FRBook() }
        return readerContainer.book
    }

    var folioReader: FolioReader {
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
    func initialization() {
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
    }

    // MARK: - View life cicle

    override open func viewDidLoad() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }
        
        super.viewDidLoad()

        screenBounds = self.getScreenBounds()
        
        // Layout
        collectionViewLayout.scrollDirection = .direction(withConfiguration: self.readerConfig)
        
        //let background = folioReader.isNight(self.readerConfig.nightModeBackground, UIColor.white)
        let background = self.readerConfig.themeModeBackground[folioReader.themeMode]
        view.backgroundColor = background

        // CollectionView
        let collectionViewFrame = frameForCollectionView(outerBounds: screenBounds)
        collectionView = UICollectionView(frame: collectionViewFrame, collectionViewLayout: collectionViewLayout)
        //collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.autoresizingMask = .init(rawValue: 0)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = background
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        collectionView.isPrefetchingEnabled = false
        
        // Register cell classes
        collectionView.register(FolioReaderPage.self, forCellWithReuseIdentifier: kReuseCellIdentifier)

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
            let frame = self.frameForPageIndicatorView(outerBounds: screenBounds)
            pageIndicatorView = FolioReaderPageIndicator(frame: frame, readerConfig: readerConfig, folioReader: folioReader)
            if let pageIndicatorView = pageIndicatorView {
                view.addSubview(pageIndicatorView)
            }
        }

        guard let readerContainer = readerContainer else { return }
        self.scrollScrubber = ScrollScrubber(frame: frameForScrollScrubber(outerBounds: screenBounds), withReaderContainer: readerContainer)
        self.scrollScrubber?.delegate = self
        if let scrollScrubber = scrollScrubber {
            view.addSubview(scrollScrubber.slider)
        }
        
        // Menus
        let menuPageTab = FolioReaderPageMenu(folioReader: folioReader, readerConfig: readerConfig)
        menuPageTab.tabBarItem = .init(title: "Page", image: nil, tag: 0)
        menuTabs.append(menuPageTab)
        
        let menuFontStyleTab = FolioReaderFontsMenu(folioReader: folioReader, readerConfig: readerConfig)
        menuFontStyleTab.tabBarItem = .init(title: "Font", image: nil, tag: 1)
        menuTabs.append(menuFontStyleTab)

        let menuParagraphTab = FolioReaderParagraphMenu(folioReader: folioReader, readerConfig: readerConfig)
        menuParagraphTab.tabBarItem = .init(title: "Paragraph", image: nil, tag: 2)
        menuTabs.append(menuParagraphTab)

        let menuAdvancedTab = FolioReaderAdvancedMenu(folioReader: folioReader, readerConfig: readerConfig)
        menuAdvancedTab.tabBarItem = .init(title: "Advanced", image: nil, tag: 3)
        menuTabs.append(menuAdvancedTab)

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
    
    override open func viewWillLayoutSubviews() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        super.viewWillLayoutSubviews()
        
        
    }
    
    override open func viewDidLayoutSubviews() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        super.viewDidLayoutSubviews()

        screenBounds = self.getScreenBounds()
        loadingView.center = view.center

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

    
    
    // MARK: - View Transition
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if readerConfig.debug.contains(.viewTransition) {
            print("BEGINTRANSROTATE fromBounds=\(collectionView.bounds) fromContentSize=\(collectionView.contentSize) fromItemSize=\(collectionViewLayout.itemSize) to=\(size) \(String(describing: coordinator.debugDescription))")
        }
        
        guard folioReader.isReaderReady else { return }

        if readerConfig.debug.contains(.viewTransition) {
            self.collectionView.indexPathsForVisibleItems.forEach {
                print("BEGIN2TRANSROTATE \($0.debugDescription)")
            }
        }
        
        //compute new screen bounds
        if readerConfig.debug.contains(.viewTransition) {
            self.collectionView.indexPathsForVisibleItems.forEach {
                print("BEGIN2TRANSROTATE \($0.debugDescription)")
            }
        }
        
        var bounds = view.frame
        bounds.size = size
        if #available(iOS 11.0, *) {
            bounds.size.height = bounds.size.height - view.safeAreaInsets.bottom
        }
        if readerConfig.debug.contains(.viewTransition) {
            print("viewWillTransition size=\(size) newBounds=\(bounds) screenBounds=\(screenBounds) collectionViewFrame=\(collectionView.frame)")
        }
        
        updateCurrentPage()
        updatePageOffsetRate()
        
        coordinator.animate { [self]_ in
            
        } completion: { [self] _ in
            guard let currentPage = self.currentPage else {
                return
            }

            // After rotation fix internal page offset
            var pageOffset = (currentPage.webView?.scrollView.contentSize.forDirection(withConfiguration: self.readerConfig) ?? 0) * self.pageOffsetRate

            // Fix the offset for paged scroll
            if (self.readerConfig.scrollDirection == .horizontal && self.pageWidth != 0) {
                let page = floor(pageOffset / self.pageWidth)
                pageOffset = page * self.pageWidth
            }

            let pageOffsetPoint = self.readerConfig.isDirection(CGPoint(x: 0, y: pageOffset), CGPoint(x: pageOffset, y: 0), CGPoint(x: 0, y: pageOffset))
            currentPage.webView?.scrollView.setContentOffset(pageOffsetPoint, animated: true)
            
            updateCurrentPage()
            updatePageOffsetRate()
        }
    }
    
    func viewWillTransitionTemp(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        return
        
        
        let itemSize = CGSize(
            width: size.width,
            height: size.height - UIApplication.shared.statusBarFrame.height - 20)
        self.collectionViewLayout.itemSize = itemSize
        self.collectionView.setContentOffset(
            CGPoint(x: CGFloat(self.currentPageNumber-1) * itemSize.width,
                    y: 0),
            animated: false)
        self.collectionViewLayout.invalidateLayout()
        
        if readerConfig.debug.contains(.viewTransition) {
            print("WILLTRANSROTATE \(self.currentPageNumber) \(self.collectionViewLayout.itemSize)")
            self.collectionView.indexPathsForVisibleItems.forEach {
                print("BEGIN3TRANSROTATE \($0.debugDescription)")
            }
        }
        
        updateCurrentPage()
        guard let currentPage = self.currentPage else {
            return
        }
        
        if readerConfig.debug.contains(.viewTransition) {
            print("WILLTRANS2ROTATE \(self.currentPageNumber) \(self.collectionViewLayout.itemSize) \(currentPage.pageNumber!)")
            self.collectionView.indexPathsForVisibleItems.forEach {
                print("BEGIN3TRANSROTATE \($0.debugDescription)")
            }
        }

//            self.collectionView.collectionViewLayout.invalidateLayout()
        
        if readerConfig.debug.contains(.viewTransition) {
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
        
        if readerConfig.debug.contains(.viewTransition) {
            print("WILLTRANS4ROTATE \(self.currentPageNumber) \(self.collectionViewLayout.itemSize) \(currentPage.pageNumber!)")
            self.collectionView.indexPathsForVisibleItems.forEach {
                print("BEGIN3TRANSROTATE \($0.debugDescription)")
            }
        }
        
        if readerConfig.debug.contains(.viewTransition) {
            print("BEFOREANIMATIONTRANSROTATE fromBounds=\(self.collectionView.bounds) fromContentSize=\(self.collectionView.contentSize) fromItemSize=\(self.collectionViewLayout.itemSize) offset=\(self.collectionView.contentOffset) to=\(size)")
        }
        coordinator.animate { _ in
            self.pageIndicatorView?.frame = self.frameForPageIndicatorView(outerBounds: self.screenBounds)
            self.pageIndicatorView?.reloadView(updateShadow: true)
        
            
            self.scrollScrubber?.slider.frame = self.frameForScrollScrubber(outerBounds: self.screenBounds)
            
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
            if self.readerConfig.debug.contains(.viewTransition) {
                print("AFTERANIMATIONTRANSROTATE bounds=\(self.collectionView.bounds) contentSize=\(self.collectionView.contentSize) itemSize=\(self.collectionViewLayout.itemSize) offset=\(self.collectionView.contentOffset) to=\(size)")
            }
            
            
            let frameForCurrentPage = self.frameForPage(self.currentPageNumber)
            self.collectionView.scrollRectToVisible(frameForCurrentPage, animated: false)
            
            if self.readerConfig.debug.contains(.viewTransition) {
                print("AFTERANIMATION2TRANSROTATE bounds=\(self.collectionView.bounds) contentSize=\(self.collectionView.contentSize) itemSize=\(self.collectionViewLayout.itemSize) offset=\(self.collectionView.contentOffset) frameForCurrentPage=\(frameForCurrentPage)")
            }
            
            //DID
            if self.readerConfig.debug.contains(.viewTransition) {
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
            
            if self.readerConfig.debug.contains(.viewTransition) {
                print("DID2TRANSROTATE \(self.currentPageNumber) \(self.collectionViewLayout.itemSize) \(currentPage.pageNumber!)")
                self.collectionView.indexPathsForVisibleItems.forEach {
                    print("DID2TRANSROTATE \($0.debugDescription)")
                }
            }
            
            self.updateCurrentPage(currentPage)
            
            if self.readerConfig.debug.contains(.viewTransition) {
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
            
            if self.readerConfig.debug.contains(.viewTransition) {
                print("DID4TRANSROTATE \(self.currentPageNumber) \(self.collectionViewLayout.itemSize) \(currentPage.pageNumber!)")
                self.collectionView.indexPathsForVisibleItems.forEach {
                    print("DID4TRANSROTATE \($0.debugDescription)")
                }
            }
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
    
    
    
    
    // MARK: NavigationBar Actions

    @objc func closeReader(_ sender: UIBarButtonItem) {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        dismiss()
        folioReader.close()
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
    
    @objc func decreaseCollectionViewSize(_ sender: UIBarButtonItem) {
        tempCollectionViewInset += 50.0
        updateSubviewFrames()
    }
}

//
//  SubViews.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/14.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import Foundation

extension FolioReaderCenter {
    
    func updateSubviewFrames() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        self.pageIndicatorView?.frame = self.frameForPageIndicatorView(outerBounds: screenBounds)
        self.scrollScrubber?.frame = self.frameForScrollScrubber(outerBounds: screenBounds)
        
        
        var collectionViewFrame = self.frameForCollectionView(outerBounds: screenBounds)
        collectionViewFrame = collectionViewFrame.insetBy(dx: tempCollectionViewInset, dy: tempCollectionViewInset)
        pageWidth = collectionViewFrame.width
        pageHeight = collectionViewFrame.height
//        let itemSize = CGSize(
//            width: collectionViewFrame.size.width,
//            height: collectionViewFrame.size.height)
//        self.collectionViewLayout.itemSize = itemSize
        self.collectionView.frame = collectionViewFrame

        self.collectionView.setContentOffset(
            self.readerConfig.isDirection(
                CGPoint(x: 0, y: CGFloat(self.currentPageNumber-1) * pageHeight),
                CGPoint(x: CGFloat(self.currentPageNumber-1) * pageWidth, y: 0),
                CGPoint(x: CGFloat(self.currentPageNumber-1) * pageWidth, y: 0))
            ,
            animated: false
        )
        self.collectionViewLayout.invalidateLayout()
    }

    func frameForPageIndicatorView(outerBounds: CGRect) -> CGRect {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var bounds = CGRect(x: 0, y: outerBounds.size.height-pageIndicatorHeight, width: outerBounds.size.width, height: pageIndicatorHeight)
        
        if #available(iOS 11.0, *) {
            bounds.size.height = bounds.size.height + view.safeAreaInsets.bottom
        }
        
        return bounds
    }

    func frameForScrollScrubber(outerBounds: CGRect) -> CGRect {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        let scrubberY: CGFloat = ((self.readerConfig.shouldHideNavigationOnTap == true || self.readerConfig.hideBars == true) ? 50 : 74)
        return CGRect(x: self.pageWidth + 10, y: scrubberY, width: 40, height: (self.pageHeight - 100))
    }

    func frameForCollectionView(outerBounds: CGRect) -> CGRect {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var bounds = CGRect(x: 0, y: 0, width: outerBounds.size.width, height: outerBounds.size.height-pageIndicatorHeight)
        
        if #available(iOS 11.0, *) {
            bounds.size.height = bounds.size.height + view.safeAreaInsets.bottom
        }
        return bounds
    }
    
    func getScreenBounds() -> CGRect {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        var bounds = view.frame
        
        if #available(iOS 11.0, *) {
            if readerConfig.debug.contains(.viewTransition) {
                print("getScreenBounds view.frame=\(bounds) view.safeAreaInsets=\(view.safeAreaInsets)")
            }
            bounds.size.height = bounds.size.height - view.safeAreaInsets.bottom
        }
        
        if readerConfig.debug.contains(.borderHighlight) {
            print("getScreenBounds \(bounds) \(UIApplication.shared.statusBarOrientation.rawValue)")
        }
        
        return bounds
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
        let lrp = UIBarButtonItem(image: logoIcon, style: .plain, target: self, action: #selector(decreaseCollectionViewSize(_:)))

        navigationItem.leftBarButtonItems = [menu, toc]
        #if DEBUG
        navigationItem.leftBarButtonItems?.append(lrp)
        #endif

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
    func updatePageOffsetRate() {
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

}

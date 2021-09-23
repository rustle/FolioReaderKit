//
//  PresentHighlight.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/14.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import Foundation
import ZFDragableModalTransition

extension FolioReaderCenter {
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

    /**
     Present fonts and settings menu
     */
    @objc func presentFontsMenu() {
        if readerConfig.debug.contains(.functionTrace) { folioLogger("ENTER") }

        folioReader.saveReaderState()
        hideBars()

        menuBarController.setViewControllers(menuTabs, animated: true)
        menuBarController.modalPresentationStyle = .custom
        menuBarController.selectedIndex = lastMenuSelectedIndex
        
        animator = ZFModalTransitionAnimator(modalViewController: menuBarController)
        animator.isDragable = false
        animator.bounces = false
        animator.behindViewAlpha = 1.0
        animator.behindViewScale = 1.0
        animator.transitionDuration = 0.6
        animator.direction = ZFModalTransitonDirection.bottom

        menuBarController.transitioningDelegate = animator
        
        self.present(menuBarController, animated: true, completion: nil)
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

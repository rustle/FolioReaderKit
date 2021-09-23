//
//  FolioReaderMenu.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/22.
//

import Foundation

class FolioReaderMenu: UIViewController, UIGestureRecognizerDelegate {
    public var menuView: UIView!

    var readerConfig: FolioReaderConfig
    var folioReader: FolioReader
    
    init(folioReader: FolioReader, readerConfig: FolioReaderConfig) {
        self.readerConfig = readerConfig
        self.folioReader = folioReader

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadColors() {
        guard menuView != nil else { return }

        let backgroundColor = self.readerConfig.themeModeBackground[self.folioReader.themeMode]
        menuView.backgroundColor = backgroundColor
        menuView.subviews.forEach { subview in
            subview.backgroundColor = backgroundColor
            if let label = subview as? UILabel {
                label.textColor = folioReader.isNight(UIColor.lightText, UIColor.darkText)
            }
        }
    }
}

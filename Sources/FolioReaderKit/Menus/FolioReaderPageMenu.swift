//
//  FolioReaderPageMenu.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/22.
//

import Foundation

class FolioReaderPageMenu: FolioReaderMenu, SMSegmentViewDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.clear

        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FolioReaderPageMenu.tapGesture))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        // Menu view
        var visibleHeight: CGFloat = (self.readerConfig.canChangeScrollDirection ? 222 : 170) + 100 /*margin*/
        visibleHeight = self.readerConfig.canChangeFontStyle ? visibleHeight : visibleHeight - 55
        menuView = UIView(frame: CGRect(x: 0, y: view.frame.height-visibleHeight, width: view.frame.width, height: view.frame.height))
        //menuView.backgroundColor = self.folioReader.isNight(self.readerConfig.nightModeMenuBackground, UIColor.white)
        menuView.backgroundColor = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]
        menuView.autoresizingMask = .flexibleWidth
        menuView.layer.shadowColor = UIColor.black.cgColor
        menuView.layer.shadowOffset = CGSize(width: 0, height: 0)
        menuView.layer.shadowOpacity = 0.3
        menuView.layer.shadowRadius = 6
        menuView.layer.shadowPath = UIBezierPath(rect: menuView.bounds).cgPath
        menuView.layer.rasterizationScale = UIScreen.main.scale
        menuView.layer.shouldRasterize = true
        view.addSubview(menuView)

        let normalColor = UIColor(white: 0.5, alpha: 0.7)
        let selectedColor = self.readerConfig.tintColor
        let sun = UIImage(readerImageNamed: "icon-sun")
        let moon = UIImage(readerImageNamed: "icon-moon")
        let fontSmall = UIImage(readerImageNamed: "icon-font-small")
        let fontBig = UIImage(readerImageNamed: "icon-font-big")

        let sunNormal = sun?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let moonNormal = moon?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let fontSmallNormal = fontSmall?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let fontBigNormal = fontBig?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)

        let sunSelected = sun?.imageTintColor(selectedColor)?.withRenderingMode(.alwaysOriginal)
        let moonSelected = moon?.imageTintColor(selectedColor)?.withRenderingMode(.alwaysOriginal)

        // Day night mode
        let dayNight = SMSegmentView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 55),
                                     separatorColour: self.readerConfig.nightModeSeparatorColor,
                                     separatorWidth: 1,
                                     segmentProperties:  [
                                        keySegmentTitleFont: UIFont(name: "Avenir-Light", size: 17)!,
                                        keySegmentOnSelectionColour: UIColor.clear,
                                        keySegmentOffSelectionColour: UIColor.clear,
                                        keySegmentOnSelectionTextColour: selectedColor,
                                        keySegmentOffSelectionTextColour: normalColor,
                                        keyContentVerticalMargin: 17 as AnyObject
            ])
        dayNight.delegate = self
        dayNight.tag = 1
        dayNight.addSegmentWithTitle(self.readerConfig.localizedFontMenuDay, onSelectionImage: sunSelected, offSelectionImage: sunNormal)
        dayNight.addSegmentWithTitle(self.readerConfig.localizedFontMenuSerpia, onSelectionImage: sunSelected, offSelectionImage: sunNormal)
        dayNight.addSegmentWithTitle(self.readerConfig.localizedFontMenuGreen, onSelectionImage: sunSelected, offSelectionImage: sunNormal)
        dayNight.addSegmentWithTitle(self.readerConfig.localizedFontMenuDark, onSelectionImage: moonSelected, offSelectionImage: moonNormal)
        dayNight.addSegmentWithTitle(self.readerConfig.localizedFontMenuNight, onSelectionImage: moonSelected, offSelectionImage: moonNormal)
        dayNight.selectSegmentAtIndex(self.folioReader.themeMode)
        menuView.addSubview(dayNight)


        // Separator
        let line = UIView(frame: CGRect(x: 0, y: dayNight.frame.height+dayNight.frame.origin.y, width: view.frame.width, height: 1))
        line.backgroundColor = self.readerConfig.nightModeSeparatorColor
        menuView.addSubview(line)

        // Only continues if user can change scroll direction
        guard (self.readerConfig.canChangeScrollDirection == true) else {
            return
        }

        // Separator 3
        let line3 = UIView(frame: CGRect(x: 0, y: line.frame.origin.y, width: view.frame.width, height: 1))
        line3.backgroundColor = self.readerConfig.nightModeSeparatorColor
        menuView.addSubview(line3)

        let vertical = UIImage(readerImageNamed: "icon-menu-vertical")
        let horizontal = UIImage(readerImageNamed: "icon-menu-horizontal")
        let hybrid = UIImage(readerImageNamed: "icon-menu-hybrid")
        
        let verticalNormal = vertical?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let horizontalNormal = horizontal?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let hybridNormal = hybrid?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)

        let verticalSelected = vertical?.imageTintColor(selectedColor)?.withRenderingMode(.alwaysOriginal)
        let horizontalSelected = horizontal?.imageTintColor(selectedColor)?.withRenderingMode(.alwaysOriginal)
        let hybridSelected = hybrid?.imageTintColor(selectedColor)?.withRenderingMode(.alwaysOriginal)

        // Layout direction
        let layoutDirection = SMSegmentView(frame: CGRect(x: 0, y: line3.frame.origin.y, width: view.frame.width, height: 55),
                                            separatorColour: self.readerConfig.nightModeSeparatorColor,
                                            separatorWidth: 1,
                                            segmentProperties:  [
                                                keySegmentTitleFont: UIFont(name: "Avenir-Light", size: 17)!,
                                                keySegmentOnSelectionColour: UIColor.clear,
                                                keySegmentOffSelectionColour: UIColor.clear,
                                                keySegmentOnSelectionTextColour: selectedColor,
                                                keySegmentOffSelectionTextColour: normalColor,
                                                keyContentVerticalMargin: 17 as AnyObject
            ])
        layoutDirection.delegate = self
        layoutDirection.tag = 3
        layoutDirection.addSegmentWithTitle(self.readerConfig.localizedLayoutVertical, onSelectionImage: verticalSelected, offSelectionImage: verticalNormal)
        layoutDirection.addSegmentWithTitle(self.readerConfig.localizedLayoutHorizontal, onSelectionImage: horizontalSelected, offSelectionImage: horizontalNormal)
        layoutDirection.addSegmentWithTitle(self.readerConfig.localizedLayoutHybrid, onSelectionImage: hybridSelected, offSelectionImage: hybridNormal)

        var scrollDirection = FolioReaderScrollDirection(rawValue: self.folioReader.currentScrollDirection)

        if scrollDirection == .defaultVertical && self.readerConfig.scrollDirection != .defaultVertical {
            scrollDirection = self.readerConfig.scrollDirection
        }

        switch scrollDirection ?? .vertical {
        case .vertical, .defaultVertical:
            layoutDirection.selectSegmentAtIndex(FolioReaderScrollDirection.vertical.rawValue)
        case .horizontal:
            layoutDirection.selectSegmentAtIndex(FolioReaderScrollDirection.horizontal.rawValue)
        case .horizontalWithVerticalContent:
            layoutDirection.selectSegmentAtIndex(FolioReaderScrollDirection.horizontalWithVerticalContent.rawValue)
        }
        menuView.addSubview(layoutDirection)
        
        // Sepatator 4
        let lineB4MarginV = UIView(
            frame: CGRect(
                x: 0,
                y: line3.frame.origin.y + 56,
                width: view.frame.width,
                height: 1
            )
        )
        lineB4MarginV.backgroundColor = self.readerConfig.nightModeSeparatorColor
        menuView.addSubview(lineB4MarginV)
        
        let topMarginIncrease = UIImage(readerImageNamed: "icon-top-margin-increase")
        let topMarginDecrease = UIImage(readerImageNamed: "icon-top-margin-decrease")

        let botMarginIncrease = UIImage(readerImageNamed: "icon-bot-margin-increase")
        let botMarginDecrease = UIImage(readerImageNamed: "icon-bot-margin-decrease")
        
        let marginMenuV = SMSegmentView(
            frame: CGRect(
                x: 0,
                y: lineB4MarginV.frame.minY,
                width: view.frame.width,
                height: 55
            ),
            separatorColour: self.readerConfig.nightModeSeparatorColor,
            separatorWidth: 1,
            segmentProperties: [
                keySegmentTitleFont: UIFont(name: "Avenir-Light", size: 17)!,
                keySegmentOnSelectionColour: UIColor.clear,
                keySegmentOffSelectionColour: UIColor.clear,
                keySegmentOnSelectionTextColour: selectedColor,
                keySegmentOffSelectionTextColour: normalColor,
                keyContentVerticalMargin: 17 as AnyObject
            ])
        marginMenuV.delegate = self
        marginMenuV.tag = 4
        // top margin decrease / text placeholder / increase
        marginMenuV.addSegmentWithTitle(nil, onSelectionImage: topMarginDecrease, offSelectionImage: topMarginDecrease)
        marginMenuV.addSegmentWithTitle("PH", onSelectionImage: nil, offSelectionImage: nil)
        marginMenuV.addSegmentWithTitle(nil, onSelectionImage: topMarginIncrease, offSelectionImage: topMarginIncrease)
        
        // bot margin decrease / text placeholder / increase
        marginMenuV.addSegmentWithTitle(nil, onSelectionImage: botMarginDecrease, offSelectionImage: botMarginDecrease)
        marginMenuV.addSegmentWithTitle("PH", onSelectionImage: nil, offSelectionImage: nil)
        marginMenuV.addSegmentWithTitle(nil, onSelectionImage: botMarginIncrease, offSelectionImage: botMarginIncrease)
        
        menuView.addSubview(marginMenuV)

        let topMarginText = UILabel(
            frame: CGRect(
                x: marginMenuV.frame.width / 6 + 2,
                y: marginMenuV.frame.minY + 4,
                width: marginMenuV.frame.width / 6 - 4,
                height: marginMenuV.frame.height - 3
            )
        )
        topMarginText.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginTop) / 2.0)
        topMarginText.font = .systemFont(ofSize: 20, weight: .medium)
        topMarginText.adjustsFontForContentSizeCategory = true
        topMarginText.adjustsFontSizeToFitWidth = true
        topMarginText.textAlignment = .center
        topMarginText.textColor = normalColor
        topMarginText.tag = 400

        menuView.addSubview(topMarginText)

        let botMarginText = UILabel(
            frame: CGRect(
                x: marginMenuV.frame.width - marginMenuV.frame.width / 3 + 2,
                y: lineB4MarginV.frame.minY + 4,
                width: marginMenuV.frame.width / 6 - 4,
                height: marginMenuV.frame.height - 3
            )
        )
        botMarginText.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginBottom) / 2.0)
        botMarginText.font = .systemFont(ofSize: 20, weight: .medium)
        botMarginText.adjustsFontForContentSizeCategory = true
        botMarginText.adjustsFontSizeToFitWidth = true
        botMarginText.textAlignment = .center
        botMarginText.textColor = normalColor
        botMarginText.tag = 401

        menuView.addSubview(botMarginText)
        
        let lineB4MarginH = UIView(
            frame: CGRect(
                x: 0,
                y: marginMenuV.frame.maxY,
                width: view.frame.width,
                height: 1
            )
        )
        lineB4MarginH.backgroundColor = self.readerConfig.nightModeSeparatorColor
        menuView.addSubview(lineB4MarginH)
        
        let leftMarginIncrease = UIImage(readerImageNamed: "icon-left-margin-increase")
        let leftMarginDecrease = UIImage(readerImageNamed: "icon-left-margin-decrease")

        let rightMarginIncrease = UIImage(readerImageNamed: "icon-right-margin-increase")
        let rightMarginDecrease = UIImage(readerImageNamed: "icon-right-margin-decrease")
        
        let marginMenuH = SMSegmentView(
            frame: CGRect(
                x: 0,
                y: lineB4MarginH.frame.maxY,
                width: view.frame.width,
                height: 55
            ),
            separatorColour: self.readerConfig.nightModeSeparatorColor,
            separatorWidth: 1,
            segmentProperties: [
                keySegmentTitleFont: UIFont(name: "Avenir-Light", size: 17)!,
                keySegmentOnSelectionColour: UIColor.clear,
                keySegmentOffSelectionColour: UIColor.clear,
                keySegmentOnSelectionTextColour: selectedColor,
                keySegmentOffSelectionTextColour: normalColor,
                keyContentVerticalMargin: 17 as AnyObject
            ])
        marginMenuH.delegate = self
        marginMenuH.tag = 5
        
        marginMenuH.addSegmentWithTitle(nil, onSelectionImage: leftMarginDecrease, offSelectionImage: leftMarginDecrease)
        marginMenuH.addSegmentWithTitle("PH", onSelectionImage: nil, offSelectionImage: nil)
        marginMenuH.addSegmentWithTitle(nil, onSelectionImage: leftMarginIncrease, offSelectionImage: leftMarginIncrease)
        marginMenuH.addSegmentWithTitle(nil, onSelectionImage: rightMarginDecrease, offSelectionImage: rightMarginDecrease)
        marginMenuH.addSegmentWithTitle("PH", onSelectionImage: nil, offSelectionImage: nil)
        marginMenuH.addSegmentWithTitle(nil, onSelectionImage: rightMarginIncrease, offSelectionImage: rightMarginIncrease)
        
        menuView.addSubview(marginMenuH)
        
        let leftMarginText = UILabel(
            frame: CGRect(
                x: marginMenuH.frame.width / 6 + 2,
                y: marginMenuH.frame.minY + 4,
                width: marginMenuH.frame.width / 6 - 4,
                height: marginMenuH.frame.height - 3
            )
        )
        leftMarginText.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginLeft) / 2.0)
        leftMarginText.font = .systemFont(ofSize: 20, weight: .medium)
        leftMarginText.adjustsFontForContentSizeCategory = true
        leftMarginText.adjustsFontSizeToFitWidth = true
        leftMarginText.textAlignment = .center
        leftMarginText.textColor = normalColor
        leftMarginText.tag = 402

        menuView.addSubview(leftMarginText)

        let rightMarginText = UILabel(
            frame: CGRect(
                x: marginMenuH.frame.width - marginMenuH.frame.width / 3 + 2,
                y: marginMenuH.frame.minY + 4,
                width: marginMenuH.frame.width / 6 - 4,
                height: marginMenuV.frame.height - 3
            )
        )
        rightMarginText.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginRight) / 2.0)
        rightMarginText.font = .systemFont(ofSize: 20, weight: .medium)
        rightMarginText.adjustsFontForContentSizeCategory = true
        rightMarginText.adjustsFontSizeToFitWidth = true
        rightMarginText.textAlignment = .center
        rightMarginText.textColor = normalColor
        rightMarginText.tag = 403

        menuView.addSubview(rightMarginText)
        
        reloadColors()
    }

    // MARK: - SMSegmentView delegate

    func segmentView(_ segmentView: SMSegmentView, didSelectSegmentAtIndex index: Int) {
        guard (self.folioReader.readerCenter?.currentPage) != nil else { return }
        guard self.folioReader.readerCenter?.layoutAdapting == false else { return }

        if segmentView.tag == 1 {   //Theme Mode

            self.folioReader.nightMode = (index >= 3)
            self.folioReader.themeMode = index

            UIView.animate(withDuration: 0.6, animations: {
                //self.menuView.backgroundColor = (self.folioReader.nightMode ? self.readerConfig.nightModeBackground : self.readerConfig.daysModeNavBackground)
                self.menuView.backgroundColor = self.readerConfig.themeModeBackground[self.folioReader.themeMode]
            })

        } else if segmentView.tag == 2 {

            //self.folioReader.currentFont = FolioReaderFont(rawValue: index)!

        }  else if segmentView.tag == 3 {

            guard self.folioReader.currentScrollDirection != index else {
                return
            }

            self.folioReader.currentScrollDirection = index
        } else if segmentView.tag == 4 {
            switch index {
            case 0:
                self.folioReader.currentMarginTop -= 5
                if self.folioReader.currentMarginTop < 0 {
                    self.folioReader.currentMarginTop = 0
                }
                if let textView = menuView.viewWithTag(400) as? UILabel {
                    textView.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginTop) / 2.0)
                }
                break;
            case 2:
                self.folioReader.currentMarginTop += 5
                if self.folioReader.currentMarginTop > 50 {
                    self.folioReader.currentMarginTop = 50
                }
                if let textView = menuView.viewWithTag(400) as? UILabel {
                    textView.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginTop) / 2.0)
                }
                break;
            case 3:
                self.folioReader.currentMarginBottom -= 5
                if self.folioReader.currentMarginBottom < 0 {
                    self.folioReader.currentMarginBottom = 0
                }
                if let textView = menuView.viewWithTag(401) as? UILabel {
                    textView.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginBottom) / 2.0)
                }
                break;
            case 5:
                self.folioReader.currentMarginBottom += 5
                if self.folioReader.currentMarginBottom > 50 {
                    self.folioReader.currentMarginBottom = 50
                }
                if let textView = menuView.viewWithTag(401) as? UILabel {
                    textView.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginBottom) / 2.0)
                }
                break;
            default:
                break;
            }
        } else if segmentView.tag == 5 {
            switch index {
            case 0:
                self.folioReader.currentMarginLeft -= 5
                if self.folioReader.currentMarginLeft < 0 {
                    self.folioReader.currentMarginLeft = 0
                }
                if let textView = menuView.viewWithTag(402) as? UILabel {
                    textView.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginLeft) / 2.0)
                }
                break;
            case 2:
                self.folioReader.currentMarginLeft += 5
                if self.folioReader.currentMarginLeft > 50 {
                    self.folioReader.currentMarginLeft = 50
                }
                if let textView = menuView.viewWithTag(402) as? UILabel {
                    textView.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginLeft) / 2.0)
                }
                break;
            case 3:
                self.folioReader.currentMarginRight -= 5
                if self.folioReader.currentMarginRight < 0 {
                    self.folioReader.currentMarginRight = 0
                }
                if let textView = menuView.viewWithTag(403) as? UILabel {
                    textView.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginRight) / 2.0)
                }
                break;
            case 5:
                self.folioReader.currentMarginRight += 5
                if self.folioReader.currentMarginRight > 50 {
                    self.folioReader.currentMarginRight = 50
                }
                if let textView = menuView.viewWithTag(403) as? UILabel {
                    textView.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginRight) / 2.0)
                }
                break;
            default:
                break;
            }
        }
    }
    
    // MARK: - Gestures
    
    @objc func tapGesture() {
        dismiss() {
            self.folioReader.readerCenter?.lastMenuSelectedIndex = 0
        }
        
        if (self.readerConfig.shouldHideNavigationOnTap == false) {
            self.folioReader.readerCenter?.showBars()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer && touch.view == view {
            return true
        }
        return false
    }
    
    // MARK: - Status Bar
    
    override var prefersStatusBarHidden : Bool {
        return (self.readerConfig.shouldHideNavigationOnTap == true)
    }
}

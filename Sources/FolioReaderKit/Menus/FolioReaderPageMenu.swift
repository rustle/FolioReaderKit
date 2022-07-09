//
//  FolioReaderPageMenu.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/22.
//

import Foundation

class FolioReaderPageMenu: FolioReaderMenu, SMSegmentViewDelegate {
    let dayNightSegment = SMSegmentView()
    let dayNightSegmentHeight = CGFloat(55)
    
    let layoutDirectionSegment = SMSegmentView()
    let layoutDirectionSegmentHeight = CGFloat(55)
    
    let marginMenuVSegment = SMSegmentView()
    let marginMenuVSegmentHeight = CGFloat(55)
    
    let marginMenuHSegment = SMSegmentView()
    let marginMenuHSegmentHeight = CGFloat(55)
    
    let vLinkedButton = UIButton()
    let topMarginText = UILabel()
    let botMarginText = UILabel()
    
    let hLinkedButton = UIButton()
    let leftMarginText = UILabel()
    let rightMarginText = UILabel()
    
    let lineAfterDayNight = UIView()
    let lineB4MarginV = UIView()
    let lineB4MarginH = UIView()
    
    let marginLinked = UIImage(readerImageNamed: "icon-page-linked")
    let marginUnlinked = UIImage(readerImageNamed: "icon-page-unlinked")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FolioReaderPageMenu.tapGesture))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        let menuHeight: CGFloat = self.readerConfig.canChangeScrollDirection ? 220 : 170 + 8
        let tabBarHeight: CGFloat = self.folioReader.readerCenter?.menuBarController.tabBar.frame.height ?? 0
        let safeAreaInsetBottom: CGFloat = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        let visibleHeight = menuHeight + tabBarHeight + safeAreaInsetBottom
        
        //menuView.backgroundColor = self.folioReader.isNight(self.readerConfig.nightModeMenuBackground, UIColor.white)
        menuView.backgroundColor = self.readerConfig.themeModeMenuBackground[self.folioReader.themeMode]
        menuView.layer.shadowColor = UIColor.black.cgColor
        menuView.layer.shadowOffset = CGSize(width: 0, height: 0)
        menuView.layer.shadowOpacity = 0.3
        menuView.layer.shadowRadius = 6
        menuView.layer.shadowPath = UIBezierPath(rect: menuView.bounds).cgPath
        menuView.layer.rasterizationScale = UIScreen.main.scale
        menuView.layer.shouldRasterize = true
        menuView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(menuView)
        NSLayoutConstraint.activate([
            menuView.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -visibleHeight),
            menuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menuView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        
        let normalColor = UIColor(white: 0.5, alpha: 0.7)
        let selectedColor = self.readerConfig.tintColor
        let sun = UIImage(readerImageNamed: "icon-sun")
        let moon = UIImage(readerImageNamed: "icon-moon")

        let sunNormal = sun?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let moonNormal = moon?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)

        let sunSelected = sun?.imageTintColor(selectedColor)?.withRenderingMode(.alwaysOriginal)
        let moonSelected = moon?.imageTintColor(selectedColor)?.withRenderingMode(.alwaysOriginal)

        dayNightSegment.segmentTitleFont = segmentFont
        dayNightSegment.separatorColour = self.readerConfig.nightModeSeparatorColor
        dayNightSegment.separatorWidth = 1
        dayNightSegment.segmentOnSelectionColour = UIColor.clear
        dayNightSegment.segmentOffSelectionColour = UIColor.clear
        dayNightSegment.segmentOnSelectionTextColour = selectedColor
        dayNightSegment.segmentOffSelectionTextColour = normalColor
        dayNightSegment.segmentVerticalMargin = 17
        dayNightSegment.delegate = self
        dayNightSegment.tag = 1
        dayNightSegment.addSegmentWithTitle(self.readerConfig.localizedFontMenuDay, onSelectionImage: sunSelected, offSelectionImage: sunNormal)
        dayNightSegment.addSegmentWithTitle(self.readerConfig.localizedFontMenuSerpia, onSelectionImage: sunSelected, offSelectionImage: sunNormal)
        dayNightSegment.addSegmentWithTitle(self.readerConfig.localizedFontMenuGreen, onSelectionImage: sunSelected, offSelectionImage: sunNormal)
        dayNightSegment.addSegmentWithTitle(self.readerConfig.localizedFontMenuDark, onSelectionImage: moonSelected, offSelectionImage: moonNormal)
        dayNightSegment.addSegmentWithTitle(self.readerConfig.localizedFontMenuNight, onSelectionImage: moonSelected, offSelectionImage: moonNormal)
        dayNightSegment.selectSegmentAtIndex(self.folioReader.themeMode)
        menuView.addSubview(dayNightSegment)

        // Separator
        lineAfterDayNight.backgroundColor = self.readerConfig.nightModeSeparatorColor
        lineAfterDayNight.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(lineAfterDayNight)
        
        // Only continues if user can change scroll direction
        guard (self.readerConfig.canChangeScrollDirection == true) else {
            return
        }

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
        layoutDirectionSegment.segmentTitleFont = segmentFont
        layoutDirectionSegment.separatorColour = self.readerConfig.nightModeSeparatorColor
        layoutDirectionSegment.separatorWidth = 1
        layoutDirectionSegment.segmentOnSelectionColour = UIColor.clear
        layoutDirectionSegment.segmentOffSelectionColour = UIColor.clear
        layoutDirectionSegment.segmentOnSelectionTextColour = selectedColor
        layoutDirectionSegment.segmentOffSelectionTextColour = normalColor
        layoutDirectionSegment.segmentVerticalMargin = 17
        layoutDirectionSegment.delegate = self
        layoutDirectionSegment.tag = 3
        layoutDirectionSegment.addSegmentWithTitle(self.readerConfig.localizedLayoutVertical, onSelectionImage: verticalSelected, offSelectionImage: verticalNormal)
        layoutDirectionSegment.addSegmentWithTitle(self.readerConfig.localizedLayoutHorizontal, onSelectionImage: horizontalSelected, offSelectionImage: horizontalNormal)
        layoutDirectionSegment.addSegmentWithTitle(self.readerConfig.localizedLayoutHybrid, onSelectionImage: hybridSelected, offSelectionImage: hybridNormal)
        
        var scrollDirection = FolioReaderScrollDirection(rawValue: self.folioReader.currentScrollDirection)

        if scrollDirection == .defaultVertical && self.readerConfig.scrollDirection != .defaultVertical {
            scrollDirection = self.readerConfig.scrollDirection
        }

        switch scrollDirection ?? .vertical {
        case .vertical, .defaultVertical:
            layoutDirectionSegment.selectSegmentAtIndex(FolioReaderScrollDirection.vertical.rawValue)
        case .horizontal:
            layoutDirectionSegment.selectSegmentAtIndex(FolioReaderScrollDirection.horizontal.rawValue)
        case .horizontalWithVerticalContent:
            layoutDirectionSegment.selectSegmentAtIndex(FolioReaderScrollDirection.horizontalWithVerticalContent.rawValue)
        }
        menuView.addSubview(layoutDirectionSegment)

        
        lineB4MarginV.backgroundColor = self.readerConfig.nightModeSeparatorColor
        menuView.addSubview(lineB4MarginV)
        
        
        let topMarginIncrease = UIImage(readerImageNamed: "icon-top-margin-increase")
        let topMarginDecrease = UIImage(readerImageNamed: "icon-top-margin-decrease")

        let botMarginIncrease = UIImage(readerImageNamed: "icon-bot-margin-increase")
        let botMarginDecrease = UIImage(readerImageNamed: "icon-bot-margin-decrease")
        
        marginMenuVSegment.segmentTitleFont = segmentFont
        marginMenuVSegment.separatorColour = self.readerConfig.nightModeSeparatorColor
        marginMenuVSegment.separatorWidth = 1
        marginMenuVSegment.segmentOnSelectionColour = UIColor.clear
        marginMenuVSegment.segmentOffSelectionColour = UIColor.clear
        marginMenuVSegment.segmentOnSelectionTextColour = selectedColor
        marginMenuVSegment.segmentOffSelectionTextColour = normalColor
        marginMenuVSegment.segmentVerticalMargin = 17
        marginMenuVSegment.delegate = self
        marginMenuVSegment.tag = 4
        
        marginMenuVSegment.addSegmentWithTitle(nil, onSelectionImage: topMarginDecrease, offSelectionImage: topMarginDecrease)
        marginMenuVSegment.addSegmentWithTitle("PH", onSelectionImage: nil, offSelectionImage: nil)
        marginMenuVSegment.addSegmentWithTitle(nil, onSelectionImage: topMarginIncrease, offSelectionImage: topMarginIncrease)
        marginMenuVSegment.addSegmentWithTitle(nil, onSelectionImage: nil, offSelectionImage: nil)
        marginMenuVSegment.addSegmentWithTitle(nil, onSelectionImage: botMarginIncrease, offSelectionImage: botMarginIncrease)
        marginMenuVSegment.addSegmentWithTitle("PH", onSelectionImage: nil, offSelectionImage: nil)
        marginMenuVSegment.addSegmentWithTitle(nil, onSelectionImage: botMarginDecrease, offSelectionImage: botMarginDecrease)

        menuView.addSubview(marginMenuVSegment)

//        let topMarginText = UILabel()
        topMarginText.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginTop) / 2.0)
        topMarginText.font = .systemFont(ofSize: 20, weight: .medium)
        topMarginText.adjustsFontForContentSizeCategory = true
        topMarginText.adjustsFontSizeToFitWidth = true
        topMarginText.textAlignment = .center
        topMarginText.textColor = normalColor
        topMarginText.tag = 400
        
        menuView.addSubview(topMarginText)
        
        botMarginText.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginBottom) / 2.0)
        botMarginText.font = .systemFont(ofSize: 20, weight: .medium)
        botMarginText.adjustsFontForContentSizeCategory = true
        botMarginText.adjustsFontSizeToFitWidth = true
        botMarginText.textAlignment = .center
        botMarginText.textColor = normalColor
        botMarginText.tag = 401

        menuView.addSubview(botMarginText)
        
        vLinkedButton.setImage(self.folioReader.currentVMarginLinked ? marginLinked : marginUnlinked, for: .normal)
        vLinkedButton.addTarget(self, action: #selector(linkedButtonAction(sender:)), for: .primaryActionTriggered)
        menuView.addSubview(vLinkedButton)
        
        lineB4MarginH.backgroundColor = self.readerConfig.nightModeSeparatorColor
        menuView.addSubview(lineB4MarginH)
        
        let leftMarginIncrease = UIImage(readerImageNamed: "icon-left-margin-increase")
        let leftMarginDecrease = UIImage(readerImageNamed: "icon-left-margin-decrease")

        let rightMarginIncrease = UIImage(readerImageNamed: "icon-right-margin-increase")
        let rightMarginDecrease = UIImage(readerImageNamed: "icon-right-margin-decrease")
        
        marginMenuHSegment.segmentTitleFont = segmentFont
        marginMenuHSegment.separatorColour = self.readerConfig.nightModeSeparatorColor
        marginMenuHSegment.separatorWidth = 1
        marginMenuHSegment.segmentOnSelectionColour = UIColor.clear
        marginMenuHSegment.segmentOffSelectionColour = UIColor.clear
        marginMenuHSegment.segmentOnSelectionTextColour = selectedColor
        marginMenuHSegment.segmentOffSelectionTextColour = normalColor
        marginMenuHSegment.segmentVerticalMargin = 17
        marginMenuHSegment.delegate = self
        marginMenuHSegment.tag = 5
        
        marginMenuHSegment.addSegmentWithTitle(nil, onSelectionImage: leftMarginDecrease, offSelectionImage: leftMarginDecrease)
        marginMenuHSegment.addSegmentWithTitle("PH", onSelectionImage: nil, offSelectionImage: nil)
        marginMenuHSegment.addSegmentWithTitle(nil, onSelectionImage: leftMarginIncrease, offSelectionImage: leftMarginIncrease)
        marginMenuHSegment.addSegmentWithTitle(nil, onSelectionImage: nil, offSelectionImage: nil)
        marginMenuHSegment.addSegmentWithTitle(nil, onSelectionImage: rightMarginIncrease, offSelectionImage: rightMarginIncrease)
        marginMenuHSegment.addSegmentWithTitle("PH", onSelectionImage: nil, offSelectionImage: nil)
        marginMenuHSegment.addSegmentWithTitle(nil, onSelectionImage: rightMarginDecrease, offSelectionImage: rightMarginDecrease)

        menuView.addSubview(marginMenuHSegment)
        
        leftMarginText.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginLeft) / 2.0)
        leftMarginText.font = .systemFont(ofSize: 20, weight: .medium)
        leftMarginText.adjustsFontForContentSizeCategory = true
        leftMarginText.adjustsFontSizeToFitWidth = true
        leftMarginText.textAlignment = .center
        leftMarginText.textColor = normalColor
        leftMarginText.tag = 402

        menuView.addSubview(leftMarginText)

        rightMarginText.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginRight) / 2.0)
        rightMarginText.font = .systemFont(ofSize: 20, weight: .medium)
        rightMarginText.adjustsFontForContentSizeCategory = true
        rightMarginText.adjustsFontSizeToFitWidth = true
        rightMarginText.textAlignment = .center
        rightMarginText.textColor = normalColor
        rightMarginText.tag = 403

        menuView.addSubview(rightMarginText)
        
        hLinkedButton.setImage(self.folioReader.currentHMarginLinked ? marginLinked : marginUnlinked, for: .normal)
        hLinkedButton.addTarget(self, action: #selector(linkedButtonAction(sender:)), for: .primaryActionTriggered)
        menuView.addSubview(hLinkedButton)
        
        reloadColors()
    }
    
    override func layoutSubviews(frame: CGRect) {
        
        //menuView.frame = CGRect(x: 0, y: frame.height-visibleHeight, width: frame.width, height: frame.height)
        dayNightSegment.frame = CGRect(x: 0, y: 0, width: frame.width, height: dayNightSegmentHeight)
        dayNightSegment.segmentTitleFont = segmentFont  //to trigger segment width re-calculation
        lineAfterDayNight.frame = CGRect(x: 0, y: dayNightSegment.frame.maxY, width: frame.width, height: 1)
        
        layoutDirectionSegment.frame = CGRect(x: 0, y: lineAfterDayNight.frame.maxY,width: frame.width, height: layoutDirectionSegmentHeight)
        layoutDirectionSegment.segmentTitleFont = segmentFont  //to trigger segment width re-calculation
        lineB4MarginV.frame = CGRect(x: 0, y: layoutDirectionSegment.frame.maxY, width: frame.width, height: 1)
        
        marginMenuVSegment.frame = CGRect(x: 0, y: lineB4MarginV.frame.maxY, width: frame.width, height: marginMenuVSegmentHeight)
        marginMenuVSegment.segmentTitleFont = segmentFont  //to trigger segment width re-calculation

        topMarginText.frame = CGRect(
            x: marginMenuVSegment.frame.width / 7 + 2,
            y: marginMenuVSegment.frame.minY + 4,
            width: marginMenuVSegment.frame.width / 7 - 4,
            height: marginMenuVSegment.frame.height - 3
        )
        
        botMarginText.frame = CGRect(
            x: marginMenuVSegment.frame.width - marginMenuVSegment.frame.width / 7 * 2 + 2,
            y: lineB4MarginV.frame.minY + 4,
            width: marginMenuVSegment.frame.width / 7 - 4,
            height: marginMenuVSegment.frame.height - 3
        )
        
        vLinkedButton.frame = CGRect(
            x: marginMenuVSegment.frame.width / 7 * 3 + 2,
            y: marginMenuVSegment.frame.minY + 4,
            width: marginMenuVSegment.frame.width / 7 - 4,
            height: marginMenuVSegment.frame.height - 3
        )
        
        lineB4MarginH.frame = CGRect(x: 0, y: marginMenuVSegment.frame.maxY, width: frame.width, height: 1)
        
        marginMenuHSegment.frame = CGRect(x: 0, y: lineB4MarginH.frame.maxY, width: frame.width, height: marginMenuVSegmentHeight)
        marginMenuHSegment.segmentTitleFont = segmentFont  //to trigger segment width re-calculation

        leftMarginText.frame = CGRect(
            x: marginMenuHSegment.frame.width / 7 + 2,
            y: marginMenuHSegment.frame.minY + 4,
            width: marginMenuHSegment.frame.width / 7 - 4,
            height: marginMenuHSegment.frame.height - 3
        )
        
        rightMarginText.frame = CGRect(
            x: marginMenuHSegment.frame.width - marginMenuHSegment.frame.width / 7 * 2 + 2,
            y: marginMenuHSegment.frame.minY + 4,
            width: marginMenuHSegment.frame.width / 7 - 4,
            height: marginMenuVSegment.frame.height - 3
        )
        
        hLinkedButton.frame = CGRect(
            x: marginMenuHSegment.frame.width / 7 * 3 + 2,
            y: marginMenuHSegment.frame.minY + 4,
            width: marginMenuHSegment.frame.width / 7 - 4,
            height: marginMenuHSegment.frame.height - 3
        )
        
    }
    
    // MARK: - SMSegmentView delegate

    func segmentView(_ segmentView: SMSegmentView, didSelectSegmentAtIndex index: Int) {
        guard let currentPage = self.folioReader.readerCenter?.currentPage,
              currentPage.layoutAdapting == false else { return }

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
                (menuView.viewWithTag(400) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginTop) / 2.0)
                break;
            case 2:
                self.folioReader.currentMarginTop += 5
                (menuView.viewWithTag(400) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginTop) / 2.0)
                break;
            case 4:
                self.folioReader.currentMarginBottom += 5
                (menuView.viewWithTag(401) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginBottom) / 2.0)
                break;
            case 6:
                self.folioReader.currentMarginBottom -= 5
                (menuView.viewWithTag(401) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginBottom) / 2.0)
                break;
            default:
                break;
            }
            if self.folioReader.currentVMarginLinked {
                switch index {
                case 0:
                    self.folioReader.currentMarginBottom -= 5
                    (menuView.viewWithTag(401) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginBottom) / 2.0)
                    break;
                case 2:
                    self.folioReader.currentMarginBottom += 5
                    (menuView.viewWithTag(401) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginBottom) / 2.0)
                    break;
                case 4:
                    self.folioReader.currentMarginTop += 5
                    (menuView.viewWithTag(400) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginTop) / 2.0)
                    break;
                case 6:
                    self.folioReader.currentMarginTop -= 5
                    (menuView.viewWithTag(400) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginTop) / 2.0)
                    break;
                default:
                    break;
                }
                currentPage.byWritingMode(
                    horizontal: { currentPage.updateViewerLayout(delay: 0.2) },
                    vertical: { currentPage.updateRuntimStyle(delay: 0.4) }
                )
            }
        } else if segmentView.tag == 5 {
            switch index {
            case 0:
                self.folioReader.currentMarginLeft -= 5
                (menuView.viewWithTag(402) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginLeft) / 2.0)
                break;
            case 2:
                self.folioReader.currentMarginLeft += 5
                (menuView.viewWithTag(402) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginLeft) / 2.0)
                break;
            case 4:
                self.folioReader.currentMarginRight += 5
                (menuView.viewWithTag(403) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginRight) / 2.0)
                break;
            case 6:
                self.folioReader.currentMarginRight -= 5
                (menuView.viewWithTag(403) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginRight) / 2.0)
                break;
            default:
                break;
            }
            if self.folioReader.currentHMarginLinked {
                switch index {
                case 0:
                    self.folioReader.currentMarginRight -= 5
                    (menuView.viewWithTag(403) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginRight) / 2.0)
                    break;
                case 2:
                    self.folioReader.currentMarginRight += 5
                    (menuView.viewWithTag(403) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginRight) / 2.0)
                    break;
                case 4:
                    self.folioReader.currentMarginLeft += 5
                    (menuView.viewWithTag(402) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginLeft) / 2.0)
                    break;
                case 6:
                    self.folioReader.currentMarginLeft -= 5
                    (menuView.viewWithTag(402) as? UILabel)?.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginLeft) / 2.0)
                    break;
                default:
                    break;
                }
                currentPage.byWritingMode(
                    horizontal: { currentPage.updateRuntimStyle(delay: 0.4) },
                    vertical: { currentPage.updateViewerLayout(delay: 0.2) }
                )
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
    
    @objc func linkedButtonAction(sender: Any?) {
        if sender as? UIButton == vLinkedButton {
            self.folioReader.currentVMarginLinked.toggle()
            vLinkedButton.setImage(self.folioReader.currentVMarginLinked ? marginLinked : marginUnlinked, for: .normal)
        }
        if sender as? UIButton == hLinkedButton {
            self.folioReader.currentHMarginLinked.toggle()
            hLinkedButton.setImage(self.folioReader.currentHMarginLinked ? marginLinked : marginUnlinked, for: .normal)
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

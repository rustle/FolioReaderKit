//
//  FolioReaderFontsMenu.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 27/08/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

public enum FolioReaderFont: Int {
    case andada = 0
    case lato
    case lora
    case raleway

    public static func folioReaderFont(fontName: String) -> FolioReaderFont? {
        var font: FolioReaderFont?
        switch fontName {
        case "andada": font = .andada
        case "lato": font = .lato
        case "lora": font = .lora
        case "raleway": font = .raleway
        default: break
        }
        return font
    }

    public var cssIdentifier: String {
        switch self {
        case .andada: return "andada"
        case .lato: return "lato"
        case .lora: return "lora"
        case .raleway: return "raleway"
        }
    }
}

public enum FolioReaderFontSize: Int {
    case xs = 0
    case s
    case m
    case l
    case xl

    public static func folioReaderFontSize(fontSizeStringRepresentation: String) -> FolioReaderFontSize? {
        var fontSize: FolioReaderFontSize?
        switch fontSizeStringRepresentation {
        case "textSizeOne": fontSize = .xs
        case "textSizeTwo": fontSize = .s
        case "textSizeThree": fontSize = .m
        case "textSizeFour": fontSize = .l
        case "textSizeFive": fontSize = .xl
        default: break
        }
        return fontSize
    }

    public var cssIdentifier: String {
        switch self {
        case .xs: return "textSizeOne"
        case .s: return "textSizeTwo"
        case .m: return "textSizeThree"
        case .l: return "textSizeFour"
        case .xl: return "textSizeFive"
        }
    }
}

class FolioReaderFontsMenu: UIViewController, SMSegmentViewDelegate, UIGestureRecognizerDelegate {
    var menuView: UIView!

    fileprivate var readerConfig: FolioReaderConfig
    fileprivate var folioReader: FolioReader

    init(folioReader: FolioReader, readerConfig: FolioReaderConfig) {
        self.readerConfig = readerConfig
        self.folioReader = folioReader

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.clear

        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FolioReaderFontsMenu.tapGesture))
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
        let verticalNormal = vertical?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let horizontalNormal = horizontal?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let verticalSelected = vertical?.imageTintColor(selectedColor)?.withRenderingMode(.alwaysOriginal)
        let horizontalSelected = horizontal?.imageTintColor(selectedColor)?.withRenderingMode(.alwaysOriginal)

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

        var scrollDirection = FolioReaderScrollDirection(rawValue: self.folioReader.currentScrollDirection)

        if scrollDirection == .defaultVertical && self.readerConfig.scrollDirection != .defaultVertical {
            scrollDirection = self.readerConfig.scrollDirection
        }

        switch scrollDirection ?? .vertical {
        case .vertical, .defaultVertical:
            layoutDirection.selectSegmentAtIndex(FolioReaderScrollDirection.vertical.rawValue)
        case .horizontal, .horizontalWithVerticalContent:
            layoutDirection.selectSegmentAtIndex(FolioReaderScrollDirection.horizontal.rawValue)
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
        
        let marginIncrease = UIImage(readerImageNamed: "icon-sun")
        let marginDecrease = UIImage(readerImageNamed: "icon-moon")
        
        let marginMenuV = SMSegmentView(
            frame: CGRect(
                x: 0,
                y: lineB4MarginV.frame.origin.y,
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
        marginMenuV.addSegmentWithTitle("T-", onSelectionImage: marginDecrease, offSelectionImage: marginDecrease)
        marginMenuV.addSegmentWithTitle("PH", onSelectionImage: nil, offSelectionImage: nil)
        marginMenuV.addSegmentWithTitle("T+", onSelectionImage: marginIncrease, offSelectionImage: marginIncrease)
        marginMenuV.addSegmentWithTitle("B-", onSelectionImage: marginDecrease, offSelectionImage: marginDecrease)
        marginMenuV.addSegmentWithTitle("PH", onSelectionImage: nil, offSelectionImage: nil)
        marginMenuV.addSegmentWithTitle("B+", onSelectionImage: marginIncrease, offSelectionImage: marginIncrease)
        
        menuView.addSubview(marginMenuV)

        let topMarginText = UITextView(
            frame: CGRect(
                x: view.frame.width / 6 + 2,
                y: lineB4MarginV.frame.origin.y + 4,
                width: view.frame.width / 6 - 4,
                height: marginMenuV.frame.height - 3
            )
        )
        topMarginText.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginTop) / 2.0)
        topMarginText.font = UIFont(name: "Avenir-Heavy", size: 24)
        topMarginText.textAlignment = .center
        topMarginText.textColor = normalColor
        topMarginText.tag = 400

        menuView.addSubview(topMarginText)

        let botMarginText = UITextView(
            frame: CGRect(
                x: view.frame.width - view.frame.width / 3 + 2,
                y: lineB4MarginV.frame.origin.y + 4,
                width: view.frame.width / 6 - 4,
                height: marginMenuV.frame.height - 3
            )
        )
        botMarginText.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginBottom) / 2.0)
        botMarginText.font = UIFont(name: "Avenir-Heavy", size: 24)
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
        
        marginMenuH.addSegmentWithTitle("L-", onSelectionImage: marginDecrease, offSelectionImage: marginDecrease)
        marginMenuH.addSegmentWithTitle("L+", onSelectionImage: marginIncrease, offSelectionImage: marginIncrease)
        marginMenuH.addSegmentWithTitle("R-", onSelectionImage: marginDecrease, offSelectionImage: marginDecrease)
        marginMenuH.addSegmentWithTitle("R+", onSelectionImage: marginIncrease, offSelectionImage: marginIncrease)
        
        menuView.addSubview(marginMenuH)
    }

    // MARK: - SMSegmentView delegate

    func segmentView(_ segmentView: SMSegmentView, didSelectSegmentAtIndex index: Int) {
        guard (self.folioReader.readerCenter?.currentPage) != nil else { return }
        guard self.folioReader.readerCenter?.layoutAdapting == false else { return }

        if segmentView.tag == 1 {   //Theme Mode

            self.folioReader.nightMode = Bool(index == 3)
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
                if let textView = menuView.viewWithTag(400) as? UITextView {
                    textView.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginTop) / 2.0)
                }
                break;
            case 2:
                self.folioReader.currentMarginTop += 5
                if self.folioReader.currentMarginTop > 30 {
                    self.folioReader.currentMarginTop = 30
                }
                if let textView = menuView.viewWithTag(400) as? UITextView {
                    textView.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginTop) / 2.0)
                }
                break;
            case 3:
                self.folioReader.currentMarginBottom -= 5
                if self.folioReader.currentMarginBottom < 0 {
                    self.folioReader.currentMarginBottom = 0
                }
                if let textView = menuView.viewWithTag(401) as? UITextView {
                    textView.text = String(format: "%.1f%%", Double(self.folioReader.currentMarginBottom) / 2.0)
                }
                break;
            case 5:
                self.folioReader.currentMarginBottom += 5
                if self.folioReader.currentMarginBottom > 30 {
                    self.folioReader.currentMarginBottom = 30
                }
                if let textView = menuView.viewWithTag(401) as? UITextView {
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
                break;
            case 1:
                self.folioReader.currentMarginLeft += 5
                if self.folioReader.currentMarginLeft > 25 {
                    self.folioReader.currentMarginLeft = 25
                }
                break;
            case 2:
                self.folioReader.currentMarginRight -= 5
                if self.folioReader.currentMarginRight < 0 {
                    self.folioReader.currentMarginRight = 0
                }
                break;
            case 3:
                self.folioReader.currentMarginRight += 5
                if self.folioReader.currentMarginRight > 25 {
                    self.folioReader.currentMarginRight = 25
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

class FolioReaderFontStyleMenu: UIViewController, UIGestureRecognizerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var menuView: UIView!
    var stylePicker: UIPickerView!
    var styleSlider: HADiscreteSlider!
    var weightSlider: HADiscreteSlider!
    var stylePreview: UITextView!
    
    fileprivate var readerConfig: FolioReaderConfig
    fileprivate var folioReader: FolioReader
    
    let systemFontFamilyNames = UIFont.familyNames
    let fontSizes = ["10px", "12px", "14px", "17px", "20px", "23px", "27px", "31px", "35px", "40px", "45px"]

    init(folioReader: FolioReader, readerConfig: FolioReaderConfig) {
        self.readerConfig = readerConfig
        self.folioReader = folioReader

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.clear
        
        let normalColor = UIColor(white: 0.5, alpha: 0.7)
        let selectedColor = self.readerConfig.tintColor
        let fontSmall = UIImage(readerImageNamed: "icon-font-small")
        let fontBig = UIImage(readerImageNamed: "icon-font-big")
        let fontSmallNormal = fontSmall?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let fontBigNormal = fontBig?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FolioReaderFontStyleMenu.tapGesture))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        // Menu view
        var visibleHeight: CGFloat = (self.readerConfig.canChangeScrollDirection ? 222 : 170) + 100 /*margin*/
        visibleHeight = self.readerConfig.canChangeFontStyle ? visibleHeight : visibleHeight - 55
        menuView = UIView(frame: CGRect(x: 0, y: view.frame.height-visibleHeight, width: view.frame.width, height: view.frame.height))
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
        
        stylePicker = UIPickerView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 120))
        stylePicker.dataSource = self
        stylePicker.delegate = self
        if let fontRow = systemFontFamilyNames.index(of: self.folioReader.currentFont) {
            stylePicker.selectRow(fontRow, inComponent: 0, animated: false)
        }
        menuView.addSubview(stylePicker)
        
        // Separator 2
        let lineBeforeSizeSlider = UIView(frame: CGRect(x: 0, y: stylePicker.frame.maxY, width: view.frame.width, height: 1))
        lineBeforeSizeSlider.backgroundColor = self.readerConfig.nightModeSeparatorColor
        menuView.addSubview(lineBeforeSizeSlider)

        // Font size slider
        styleSlider = HADiscreteSlider(frame: CGRect(x: 60, y: lineBeforeSizeSlider.frame.origin.y+2, width: view.frame.width-120, height: 40))
        styleSlider.tickStyle = ComponentStyle.rounded
        styleSlider.tickCount = 11
        styleSlider.tickSize = CGSize(width: 8, height: 8)

        styleSlider.thumbStyle = ComponentStyle.rounded
        styleSlider.thumbSize = CGSize(width: 28, height: 28)
        styleSlider.thumbShadowOffset = CGSize(width: 0, height: 2)
        styleSlider.thumbShadowRadius = 3
        styleSlider.thumbColor = selectedColor

        styleSlider.backgroundColor = UIColor.clear
        styleSlider.tintColor = self.readerConfig.nightModeSeparatorColor
        styleSlider.minimumValue = 0
        styleSlider.value = CGFloat(fontSizes.index(of: self.folioReader.currentFontSize) ?? 4)
        styleSlider.addTarget(self, action: #selector(FolioReaderFontStyleMenu.styleSliderValueChanged(_:)), for: UIControl.Event.valueChanged)

        // Force remove fill color
        styleSlider.layer.sublayers?.forEach({ layer in
            layer.backgroundColor = UIColor.clear.cgColor
        })

        menuView.addSubview(styleSlider)

        // Font icons
        let fontSmallView = UIImageView(frame: CGRect(x: 20, y: lineBeforeSizeSlider.frame.origin.y+14, width: 30, height: 30))
        fontSmallView.image = fontSmallNormal
        fontSmallView.contentMode = UIView.ContentMode.center
        menuView.addSubview(fontSmallView)

        let fontBigView = UIImageView(frame: CGRect(x: view.frame.width-50, y: lineBeforeSizeSlider.frame.origin.y+14, width: 30, height: 30))
        fontBigView.image = fontBigNormal
        fontBigView.contentMode = UIView.ContentMode.center
        menuView.addSubview(fontBigView)
        
        // Separator 3
        let lineBeforeWeightSlider = UIView(
            frame: CGRect(
                x: 0,
                y: styleSlider.frame.maxY,
                width: view.frame.width,
                height: 1))
        lineBeforeWeightSlider.backgroundColor = self.readerConfig.nightModeSeparatorColor
        menuView.addSubview(lineBeforeWeightSlider)

        // Weeight slider
        weightSlider = HADiscreteSlider(
            frame: CGRect(
                x: 60,
                y: lineBeforeWeightSlider.frame.origin.y+2,
                width: view.frame.width-120,
                height: 40))
        weightSlider.tickStyle = ComponentStyle.rounded
        weightSlider.tickCount = 9
        weightSlider.tickSize = CGSize(width: 8, height: 8)

        weightSlider.thumbStyle = ComponentStyle.rounded
        weightSlider.thumbSize = CGSize(width: 28, height: 28)
        weightSlider.thumbShadowOffset = CGSize(width: 0, height: 2)
        weightSlider.thumbShadowRadius = 3
        weightSlider.thumbColor = selectedColor

        weightSlider.backgroundColor = UIColor.clear
        weightSlider.tintColor = self.readerConfig.nightModeSeparatorColor
        weightSlider.minimumValue = 0
        weightSlider.value = CGFloat(Int(self.folioReader.currentFontWeight)! / 100 - 1)
        weightSlider.addTarget(self, action: #selector(FolioReaderFontStyleMenu.weightSliderValueChanged(_:)), for: UIControl.Event.valueChanged)

        // Force remove fill color
        weightSlider.layer.sublayers?.forEach({ layer in
            layer.backgroundColor = UIColor.clear.cgColor
        })

        menuView.addSubview(weightSlider)

        
        // Font Preview
        stylePreview = UITextView(
            frame: CGRect(
                x: 0,
                y: weightSlider.frame.maxY + 5,
                width: view.frame.width,
                height: 60))
        stylePreview.text = "Yet Another eBook Reader"
        stylePreview.font = UIFont(
            name: self.folioReader.currentFont,
            size: CGFloat(self.folioReader.currentFontSizeOnly)
        )
        
        menuView.addSubview(stylePreview)
    }
    
    
    
    // MARK: - Picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return systemFontFamilyNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return systemFontFamilyNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.folioReader.currentFont = systemFontFamilyNames[row]
        
        stylePreview.font = UIFont(
            name: self.folioReader.currentFont,
            size: CGFloat(self.folioReader.currentFontSizeOnly)
        )
    }
    
    // MARK: - Font slider changed
    
    @objc func styleSliderValueChanged(_ sender: HADiscreteSlider) {
        self.folioReader.currentFontSize = fontSizes[Int(sender.value)]
        stylePreview.font = UIFont(
            name: self.folioReader.currentFont,
            size: CGFloat(self.folioReader.currentFontSizeOnly)
        )
    }
    
    @objc func weightSliderValueChanged(_ sender: HADiscreteSlider) {
        self.folioReader.currentFontWeight = ((Int(sender.value) + 1) * 100).description
        stylePreview.font = UIFont(
            name: self.folioReader.currentFont,
            size: CGFloat(self.folioReader.currentFontSizeOnly)
        )
    }

    // MARK: - Gestures
    @objc func tapGesture() {
        dismiss() {
            self.folioReader.readerCenter?.lastMenuSelectedIndex = 1
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

class FolioReaderParagraphMenu: UIViewController, UIGestureRecognizerDelegate{
    
    var menuView: UIView!
    var letterSpacingSlider: HADiscreteSlider!
    var lineHeightSlider: HADiscreteSlider!
    
    fileprivate var readerConfig: FolioReaderConfig
    fileprivate var folioReader: FolioReader
    
    init(folioReader: FolioReader, readerConfig: FolioReaderConfig) {
        self.readerConfig = readerConfig
        self.folioReader = folioReader

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.clear
        
        let normalColor = UIColor(white: 0.5, alpha: 0.7)
        let selectedColor = self.readerConfig.tintColor
        let fontSmall = UIImage(readerImageNamed: "icon-font-small")
        let fontBig = UIImage(readerImageNamed: "icon-font-big")
        let fontSmallNormal = fontSmall?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let fontBigNormal = fontBig?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FolioReaderParagraphMenu.tapGesture))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        // Menu view
        var visibleHeight: CGFloat = (self.readerConfig.canChangeScrollDirection ? 222 : 170) + 100 /*margin*/
        visibleHeight = self.readerConfig.canChangeFontStyle ? visibleHeight : visibleHeight - 55
        menuView = UIView(frame: CGRect(x: 0, y: view.frame.height-visibleHeight, width: view.frame.width, height: view.frame.height))
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
        
        // Letter Spacing Slider
        letterSpacingSlider = HADiscreteSlider(
            frame: CGRect(
                x: 60,
                y: 5,
                width: view.frame.width - 120,
                height: 40))
        letterSpacingSlider.tickStyle = ComponentStyle.rounded
        letterSpacingSlider.tickCount = 11
        letterSpacingSlider.tickSize = CGSize(width: 8, height: 8)

        letterSpacingSlider.thumbStyle = ComponentStyle.rounded
        letterSpacingSlider.thumbSize = CGSize(width: 28, height: 28)
        letterSpacingSlider.thumbShadowOffset = CGSize(width: 0, height: 2)
        letterSpacingSlider.thumbShadowRadius = 3
        letterSpacingSlider.thumbColor = selectedColor

        letterSpacingSlider.backgroundColor = UIColor.clear
        letterSpacingSlider.tintColor = self.readerConfig.nightModeSeparatorColor
        letterSpacingSlider.minimumValue = 0
        letterSpacingSlider.incrementValue = 1
        letterSpacingSlider.value = CGFloat(self.folioReader.currentLetterSpacing)
        letterSpacingSlider.addTarget(self, action: #selector(FolioReaderParagraphMenu.letterSpacingSliderValueChanged(_:)), for: UIControl.Event.valueChanged)

        // Force remove fill color
        letterSpacingSlider.layer.sublayers?.forEach({ layer in
            layer.backgroundColor = UIColor.clear.cgColor
        })

        menuView.addSubview(letterSpacingSlider)
        
        // Font slider size
        lineHeightSlider = HADiscreteSlider(
            frame: CGRect(
                x: 60,
                y: letterSpacingSlider.frame.maxY+2,
                width: view.frame.width-120,
                height: 40))
        lineHeightSlider.tickStyle = ComponentStyle.rounded
        lineHeightSlider.tickCount = 11
        lineHeightSlider.tickSize = CGSize(width: 8, height: 8)

        lineHeightSlider.thumbStyle = ComponentStyle.rounded
        lineHeightSlider.thumbSize = CGSize(width: 28, height: 28)
        lineHeightSlider.thumbShadowOffset = CGSize(width: 0, height: 2)
        lineHeightSlider.thumbShadowRadius = 3
        lineHeightSlider.thumbColor = selectedColor

        lineHeightSlider.backgroundColor = UIColor.clear
        lineHeightSlider.tintColor = self.readerConfig.nightModeSeparatorColor
        lineHeightSlider.minimumValue = 0
        lineHeightSlider.value = CGFloat(self.folioReader.currentLineHeight)
        lineHeightSlider.addTarget(self, action: #selector(FolioReaderParagraphMenu.lineHeightSliderValueChanged(_:)), for: UIControl.Event.valueChanged)

        // Force remove fill color
        lineHeightSlider.layer.sublayers?.forEach({ layer in
            layer.backgroundColor = UIColor.clear.cgColor
        })

        menuView.addSubview(lineHeightSlider)
    }
    
    // MARK: - Font slider changed
    
    @objc func letterSpacingSliderValueChanged(_ sender: HADiscreteSlider) {
        self.folioReader.currentLetterSpacing = Int(sender.value)
    }
    
    @objc func lineHeightSliderValueChanged(_ sender: HADiscreteSlider) {
        self.folioReader.currentLineHeight = Int(sender.value)
    }
    
    // MARK: - Gestures
    @objc func tapGesture() {
        dismiss() {
            self.folioReader.readerCenter?.lastMenuSelectedIndex = 2
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

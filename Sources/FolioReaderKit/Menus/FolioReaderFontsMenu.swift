//
//  FolioReaderFontsMenu.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 27/08/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit



class FolioReaderFontsMenu: FolioReaderMenu, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var stylePicker: UIPickerView!
    var styleSlider: HADiscreteSlider!
    var weightSlider: HADiscreteSlider!
    var stylePreview: UITextView!
    
    let systemFontFamilyNames = UIFont.familyNames
    let fontSizes = ["15.5px", "17px", "18.5px", "20px", "22px", "24px", "26px", "28px", "30.5px", "33px", "35.5px"]

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
        
        let fontNarrow = UIImage(readerImageNamed: "icon-font-weight-narrow")
        let fontBlack = UIImage(readerImageNamed: "icon-font-weight-black")
        let fontNarrowNormal = fontNarrow?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let fontBlackNormal = fontBlack?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FolioReaderFontsMenu.tapGesture))
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
        styleSlider.tickCount = fontSizes.count
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
        styleSlider.addTarget(self, action: #selector(FolioReaderFontsMenu.styleSliderValueChanged(_:)), for: UIControl.Event.valueChanged)

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
        weightSlider.addTarget(self, action: #selector(FolioReaderFontsMenu.weightSliderValueChanged(_:)), for: UIControl.Event.valueChanged)

        // Force remove fill color
        weightSlider.layer.sublayers?.forEach({ layer in
            layer.backgroundColor = UIColor.clear.cgColor
        })

        menuView.addSubview(weightSlider)

        let fontNarrowView = UIImageView(frame: CGRect(x: 20, y: lineBeforeWeightSlider.frame.origin.y+14, width: 30, height: 30))
        fontNarrowView.image = fontNarrowNormal
        fontNarrowView.contentMode = UIView.ContentMode.center
        menuView.addSubview(fontNarrowView)

        let fontBlackView = UIImageView(frame: CGRect(x: view.frame.width-50, y: lineBeforeWeightSlider.frame.origin.y+14, width: 30, height: 30))
        fontBlackView.image = fontBlackNormal
        fontBlackView.contentMode = UIView.ContentMode.center
        menuView.addSubview(fontBlackView)
        
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
        
        // menuView.addSubview(stylePreview)
        
        reloadColors()
    }
    
    override func reloadColors() {
        super.reloadColors()

        stylePicker?.reloadAllComponents()
    }
    
    // MARK: - Picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return systemFontFamilyNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let title = NSAttributedString(
            string: systemFontFamilyNames[row],
            attributes: [
                NSAttributedString.Key.strokeColor:
                    folioReader.nightMode ? UIColor.lightText : UIColor.darkText,
                NSAttributedString.Key.foregroundColor:
                    folioReader.nightMode ? UIColor.lightText : UIColor.darkText
            ]
        )
        print("pickerView \(folioReader.nightMode)")
        return title
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


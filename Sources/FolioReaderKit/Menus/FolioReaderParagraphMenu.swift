//
//  File.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/22.
//

import Foundation

class FolioReaderParagraphMenu: FolioReaderMenu {
    
    var letterSpacingSlider: HADiscreteSlider!
    var lineHeightSlider: HADiscreteSlider!
    
    let textIndentValue = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.clear
        
        let normalColor = UIColor(white: 0.5, alpha: 0.7)
        let selectedColor = self.readerConfig.tintColor
        let charNarrow = UIImage(readerImageNamed: "icon-char-spacing-narrow")
        let charWide = UIImage(readerImageNamed: "icon-char-spacing-wide")
        let charNarrowNormal = charNarrow?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let charWideNormal = charWide?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        
        let lineNarrow = UIImage(readerImageNamed: "icon-line-height-narrow")
        let lineWide = UIImage(readerImageNamed: "icon-line-height-wide")
        let lineNarrowNormal = lineNarrow?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        let lineWideNormal = lineWide?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        
        let firstIndent = UIImage(readerImageNamed: "icon-first-line-indent")
        let firstIndentNormal = firstIndent?.imageTintColor(normalColor)?.withRenderingMode(.alwaysOriginal)
        
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
        
        let charNarrowView = UIImageView(frame: CGRect(x: 20, y: letterSpacingSlider.frame.origin.y+10, width: 30, height: 30))
        charNarrowView.image = charNarrowNormal
        charNarrowView.contentMode = UIView.ContentMode.center
        menuView.addSubview(charNarrowView)

        let charWideView = UIImageView(frame: CGRect(x: view.frame.width-50, y: letterSpacingSlider.frame.origin.y+10, width: 30, height: 30))
        charWideView.image = charWideNormal
        charWideView.contentMode = UIView.ContentMode.center
        menuView.addSubview(charWideView)
        
        // Line Spacing Slider
        lineHeightSlider = HADiscreteSlider(
            frame: CGRect(
                x: 60,
                y: letterSpacingSlider.frame.maxY+8,
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
        
        let lineNarrowView = UIImageView(frame: CGRect(x: 20, y: lineHeightSlider.frame.origin.y+6, width: 30, height: 30))
        lineNarrowView.image = lineNarrowNormal
        lineNarrowView.contentMode = UIView.ContentMode.center
        menuView.addSubview(lineNarrowView)

        let lineWideView = UIImageView(frame: CGRect(x: view.frame.width-50, y: lineHeightSlider.frame.origin.y+6, width: 30, height: 30))
        lineWideView.image = lineWideNormal
        lineWideView.contentMode = UIView.ContentMode.center
        menuView.addSubview(lineWideView)
        
        let textIndentLabel = UILabel(
            frame: CGRect(
                x: 64,
                y: lineHeightSlider.frame.maxY + 16,
                width: view.frame.width - 240, height: 32
            )
        )
        textIndentLabel.text = "First Line Indent"
        textIndentLabel.font = .systemFont(ofSize: 20)
        textIndentLabel.adjustsFontForContentSizeCategory = true
        textIndentLabel.adjustsFontSizeToFitWidth = true
        
        menuView.addSubview(textIndentLabel)
        
        let firstIndentView = UIImageView(frame: CGRect(x: 20, y: textIndentLabel.frame.origin.y+2, width: 30, height: 30))
        firstIndentView.image = firstIndentNormal
        firstIndentView.contentMode = UIView.ContentMode.center
        menuView.addSubview(firstIndentView)
        
        textIndentValue.frame = CGRect(
            x: textIndentLabel.frame.maxX + 4,
            y: textIndentLabel.frame.minY,
            width: 48,
            height: 32
        )
        textIndentValue.textAlignment = .center
        textIndentValue.text = "\(folioReader.currentTextIndent)"
        textIndentValue.font = .systemFont(ofSize: 22)
        
        menuView.addSubview(textIndentValue)
        
        let textIndentStepper = UIStepper(
            frame: CGRect(
                x: textIndentValue.frame.maxX + 4,
                y: textIndentLabel.frame.minY,
                width: view.frame.width - textIndentValue.frame.maxX - 4 - 4,
                height: textIndentLabel.frame.height
            )
        )
        textIndentStepper.isContinuous = false
        textIndentStepper.autorepeat = false
        textIndentStepper.wraps = false
        textIndentStepper.minimumValue = -4
        textIndentStepper.maximumValue = 4
        textIndentStepper.stepValue = 1
        textIndentStepper.value = Double(folioReader.currentTextIndent)
        textIndentStepper.addTarget(
            self,
            action: #selector(textIndentStepperValueChanged(_:)),
            for: .valueChanged)
        
        menuView.addSubview(textIndentStepper)
        
        reloadColors()
    }
    
    // MARK: - Font slider changed
    
    @objc func letterSpacingSliderValueChanged(_ sender: HADiscreteSlider) {
        self.folioReader.currentLetterSpacing = Int(sender.value)
    }
    
    @objc func lineHeightSliderValueChanged(_ sender: HADiscreteSlider) {
        self.folioReader.currentLineHeight = Int(sender.value)
    }
    
    @objc func textIndentStepperValueChanged(_ sender: UIStepper) {
        self.folioReader.currentTextIndent = Int(sender.value)
        textIndentValue.text = "\(folioReader.currentTextIndent)"
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

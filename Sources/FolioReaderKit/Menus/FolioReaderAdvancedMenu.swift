//
//  FolioReaderStructureMenu.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/22.
//

import Foundation

class FolioReaderAdvancedMenu: FolioReaderMenu {
    let labelFontSize = CGFloat(16)
    
    var noticeLabel: UILabel!
    var wrapParaLabel: UILabel!
    var wrapParaSwitch: UISwitch!
    
    var clearClassLabel: UILabel!
    var clearClassSwitch: UISwitch!
    
    var styleOverrideLabel: UILabel!
    var styleOverrideSegment: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.clear
        
        let normalColor = UIColor(white: 0.5, alpha: 0.7)
        let selectedColor = self.readerConfig.tintColor
        
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FolioReaderAdvancedMenu.tapGesture))
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
        
        // notice label
        noticeLabel = UILabel(
            frame: CGRect(
                x : 8, y: 8,
                width: view.frame.width - 16,
                height: 24
            )
        )
        noticeLabel.text = "Note: please reopen reader for these options to take effect"
        noticeLabel.adjustsFontSizeToFitWidth = true
        noticeLabel.baselineAdjustment = .alignCenters
        noticeLabel.textColor = .systemRed
        menuView.addSubview(noticeLabel)
        
        // reformat switches
        wrapParaLabel = UILabel(
            frame: CGRect(
                x: 16,
                y: noticeLabel.frame.maxY,
                width: view.frame.width - 32 - 48,
                height: 32)
            )
        wrapParaLabel.text = "Wrap raw text inside <p>"
        wrapParaLabel.font = .systemFont(ofSize: labelFontSize)
        wrapParaLabel.adjustsFontForContentSizeCategory = true
        wrapParaLabel.adjustsFontSizeToFitWidth = true
        
        wrapParaSwitch = UISwitch(
            frame: CGRect(
                x: wrapParaLabel.frame.maxX,
                y: wrapParaLabel.frame.minY,
                width: 48,
                height: 32)
        )
        wrapParaSwitch.isOn = self.folioReader.doWrapPara
        wrapParaSwitch.addTarget(self, action: #selector(paragraphSwitchValueChanged), for: .valueChanged)
        menuView.addSubview(wrapParaLabel)
        menuView.addSubview(wrapParaSwitch)
        
        // clear body&table styles
        clearClassLabel = UILabel(
            frame: CGRect(
                x: 16, y: wrapParaLabel.frame.maxY,
                width: view.frame.width - 32 - 48, height: 32
            )
        )
        clearClassLabel.text = "Remove unsuitable html styles"
        clearClassLabel.font = .systemFont(ofSize: labelFontSize)
        clearClassLabel.adjustsFontForContentSizeCategory = true
        clearClassLabel.adjustsFontSizeToFitWidth = true
        
        clearClassSwitch = UISwitch(
            frame: CGRect(
                x: clearClassLabel.frame.maxX,
                y: clearClassLabel.frame.minY,
                width: 48, height: 32
            )
        )
        clearClassSwitch.isOn = self.folioReader.doClearClass
        clearClassSwitch.addTarget(self, action: #selector(clearClassSwitchValueChanged), for: .valueChanged)
        menuView.addSubview(clearClassLabel)
        menuView.addSubview(clearClassSwitch)
        
        styleOverrideLabel = UILabel(
            frame: CGRect(
                x: 16, y: clearClassLabel.frame.maxY,
                width: view.frame.width - 32 - 360, height: 32
            )
        )
        styleOverrideLabel.text = "Styles to override"
        styleOverrideLabel.font = .systemFont(ofSize: labelFontSize)
        styleOverrideLabel.adjustsFontForContentSizeCategory = true
        styleOverrideLabel.adjustsFontSizeToFitWidth = true
        
        styleOverrideSegment = UISegmentedControl(
            frame: CGRect(
                x: styleOverrideLabel.frame.maxX,
                y: styleOverrideLabel.frame.minY,
                width: 360, height: 32
            )
        )
        StyleOverrideTypes.allCases.forEach {
            styleOverrideSegment.insertSegment(withTitle: $0.description, at: $0.rawValue, animated: false)
        }
        styleOverrideSegment.selectedSegmentIndex = self.folioReader.styleOverride.rawValue
        styleOverrideSegment.addTarget(self, action: #selector(styleOverrideSegmentValueChanged), for: .valueChanged)
        
        
        menuView.addSubview(styleOverrideLabel)
        menuView.addSubview(styleOverrideSegment)
        
        reloadColors()
    }
    
    @objc func paragraphSwitchValueChanged(_ sender: UISwitch) {
        self.folioReader.doWrapPara = sender.isOn
    }
    
    @objc func clearClassSwitchValueChanged(_ sender: UISwitch) {
        self.folioReader.doClearClass = sender.isOn
    }
    
    @objc func styleOverrideSegmentValueChanged(_ sender: UISegmentedControl) {
        guard let styleOverride = StyleOverrideTypes(rawValue: sender.selectedSegmentIndex) else { return }
        self.folioReader.styleOverride = styleOverride
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

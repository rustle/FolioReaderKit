//
//  FolioReaderStructureMenu.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/22.
//

import Foundation

class FolioReaderAdvancedMenu: FolioReaderMenu {
    let safeAreaHeight = CGFloat(90)    //including padding between elements

    let labelFontSize = CGFloat(16)
    
    let noticeLabel = UILabel()
    let noticeLabelHeight = CGFloat(24)
    
    let wrapParaLabel = UILabel()
    let wrapParaLabelHeight = CGFloat(32)
    let wrapParaSwitch = UISwitch()
    
    let clearClassLabel = UILabel()
    let clearClassLabelHeight = CGFloat(32)
    let clearClassSwitch = UISwitch()
    
    let styleOverrideLabel = UILabel()
    let styleOverrideLabelHeight = CGFloat(32)
    
    let styleOverrideSegment = UISegmentedControl()
    let styleOverrideSegmentHeight = CGFloat(40)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FolioReaderAdvancedMenu.tapGesture))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        let menuHeight: CGFloat = noticeLabelHeight + wrapParaLabelHeight + clearClassLabelHeight + styleOverrideLabelHeight + styleOverrideSegmentHeight + 8 + 4 + 4 + 4 + 8 + 8
        let tabBarHeight: CGFloat = self.folioReader.readerCenter?.menuBarController.tabBar.frame.height ?? 0
        let safeAreaInsetBottom: CGFloat = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        let visibleHeight = menuHeight + tabBarHeight + safeAreaInsetBottom
        
         // Menu view
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
        
        // notice label
//        noticeLabel = UILabel(
//            frame: CGRect(
//                x : 8, y: 8,
//                width: frame.width - 16,
//                height: 24
//            )
//        )
        noticeLabel.text = "Note: please reopen reader for these options to take effect"
        noticeLabel.adjustsFontSizeToFitWidth = true
        noticeLabel.baselineAdjustment = .alignCenters
        noticeLabel.textColor = .systemRed
        noticeLabel.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(noticeLabel)
        NSLayoutConstraint.activate([
            noticeLabel.topAnchor.constraint(equalTo: menuView.topAnchor, constant: 8),
            noticeLabel.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 8),
            noticeLabel.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: 8),
            noticeLabel.heightAnchor.constraint(equalToConstant: noticeLabelHeight)
        ])
        
        styleOverrideLabel.text = "Style overriden intensity"
        styleOverrideLabel.font = .systemFont(ofSize: labelFontSize)
        styleOverrideLabel.adjustsFontForContentSizeCategory = true
        styleOverrideLabel.adjustsFontSizeToFitWidth = true
        styleOverrideLabel.translatesAutoresizingMaskIntoConstraints = false

        StyleOverrideTypes.allCases.forEach {
            styleOverrideSegment.insertSegment(withTitle: $0.description, at: $0.rawValue, animated: false)
        }
        styleOverrideSegment.selectedSegmentIndex = self.folioReader.styleOverride.rawValue
        styleOverrideSegment.addTarget(self, action: #selector(styleOverrideSegmentValueChanged), for: .valueChanged)
        styleOverrideSegment.translatesAutoresizingMaskIntoConstraints = false
        
        menuView.addSubview(styleOverrideLabel)
        menuView.addSubview(styleOverrideSegment)
        
        NSLayoutConstraint.activate([
            styleOverrideLabel.topAnchor.constraint(equalTo: noticeLabel.bottomAnchor, constant: 4),
            styleOverrideLabel.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 16),
            styleOverrideLabel.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -16),
            styleOverrideLabel.heightAnchor.constraint(equalToConstant: styleOverrideLabelHeight),
            styleOverrideSegment.topAnchor.constraint(equalTo: styleOverrideLabel.bottomAnchor, constant: 4),
            styleOverrideSegment.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 16),
            styleOverrideSegment.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -16),
            styleOverrideSegment.heightAnchor.constraint(equalToConstant: styleOverrideSegmentHeight)
        ])
        
        // reformat switches
        wrapParaLabel.text = "Wrap raw text inside <p>"
        wrapParaLabel.font = .systemFont(ofSize: labelFontSize)
        wrapParaLabel.adjustsFontForContentSizeCategory = true
        wrapParaLabel.adjustsFontSizeToFitWidth = true
        wrapParaLabel.translatesAutoresizingMaskIntoConstraints = false
        
        wrapParaSwitch.isOn = self.folioReader.doWrapPara
        wrapParaSwitch.addTarget(self, action: #selector(paragraphSwitchValueChanged), for: .valueChanged)
        wrapParaSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        menuView.addSubview(wrapParaLabel)
        menuView.addSubview(wrapParaSwitch)
        
        NSLayoutConstraint.activate([
            wrapParaLabel.topAnchor.constraint(equalTo: styleOverrideSegment.bottomAnchor, constant: 4),
            wrapParaLabel.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 16),
            wrapParaLabel.trailingAnchor.constraint(equalTo: wrapParaSwitch.leadingAnchor, constant: 4),
            wrapParaLabel.heightAnchor.constraint(equalToConstant: wrapParaLabelHeight),
            wrapParaSwitch.centerYAnchor.constraint(equalTo: wrapParaLabel.centerYAnchor),
            wrapParaSwitch.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -16),
            wrapParaSwitch.widthAnchor.constraint(equalToConstant: 48),
            wrapParaSwitch.heightAnchor.constraint(equalTo: wrapParaLabel.heightAnchor)
        ])
        
        // clear body&table styles
        clearClassLabel.text = "Remove unsuitable html styles"
        clearClassLabel.font = .systemFont(ofSize: labelFontSize)
        clearClassLabel.adjustsFontForContentSizeCategory = true
        clearClassLabel.adjustsFontSizeToFitWidth = true
        clearClassLabel.translatesAutoresizingMaskIntoConstraints = false

        clearClassSwitch.isOn = self.folioReader.doClearClass
        clearClassSwitch.addTarget(self, action: #selector(clearClassSwitchValueChanged), for: .valueChanged)
        clearClassSwitch.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(clearClassLabel)
        menuView.addSubview(clearClassSwitch)
        
        NSLayoutConstraint.activate([
            clearClassLabel.topAnchor.constraint(equalTo: wrapParaLabel.bottomAnchor, constant: 4),
            clearClassLabel.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 16),
            clearClassLabel.trailingAnchor.constraint(equalTo: clearClassSwitch.leadingAnchor, constant: 4),
            clearClassLabel.heightAnchor.constraint(equalToConstant: clearClassLabelHeight),
            clearClassSwitch.centerYAnchor.constraint(equalTo: clearClassLabel.centerYAnchor),
            clearClassSwitch.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -16),
            clearClassSwitch.widthAnchor.constraint(equalToConstant: 48),
            clearClassSwitch.heightAnchor.constraint(equalTo: clearClassLabel.heightAnchor)
        ])
        
        reloadColors()
    }
    
    override func layoutSubviews(frame: CGRect) {
        
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
            self.folioReader.readerCenter?.lastMenuSelectedIndex = 3
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

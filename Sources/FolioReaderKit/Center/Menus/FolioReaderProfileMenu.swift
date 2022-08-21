//
//  FolioReaderStructureMenu.swift
//  FolioReaderKit
//
//  Created by 京太郎 on 2021/9/22.
//

import Foundation
import UIKit

class FolioReaderProfileMenu: FolioReaderMenu {
    let safeAreaHeight = CGFloat(90)    //including padding between elements

    let tableView = UITableView()
    
    var profileNames = [String]()
    
    let loadButton = UIButton()
    let overwriteButton = UIButton()
    let saveAsButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FolioReaderProfileMenu.tapGesture))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        let menuHeight: CGFloat = 200
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
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: kReuseCellIdentifier)
        tableView.separatorInset = UIEdgeInsets.zero
        //self.tableView.backgroundColor = self.folioReader.isNight(self.readerConfig.nightModeMenuBackground, self.readerConfig.menuBackgroundColor)
        tableView.separatorColor = self.folioReader.isNight(self.readerConfig.nightModeSeparatorColor, self.readerConfig.menuSeparatorColor)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        loadProfileNames()
        
        menuView.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: menuView.topAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: 20),
            tableView.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        loadButton.setTitle("Load", for: .normal)
        loadButton.addTarget(self, action: #selector(loadButtonAction(_:)), for: .primaryActionTriggered)
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        
        overwriteButton.setTitle("Overwrite", for: .normal)
        overwriteButton.addTarget(self, action: #selector(overwriteButtonAction(_:)), for: .primaryActionTriggered)
        overwriteButton.translatesAutoresizingMaskIntoConstraints = false
        
        saveAsButton.setTitle("Save As", for: .normal)
        saveAsButton.addTarget(self, action: #selector(saveasButtonAction(_:)), for: .primaryActionTriggered)
        saveAsButton.translatesAutoresizingMaskIntoConstraints = false
        
        menuView.addSubview(loadButton)
        menuView.addSubview(overwriteButton)
        menuView.addSubview(saveAsButton)
        
        NSLayoutConstraint.activate([
            loadButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 8),
            loadButton.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            loadButton.widthAnchor.constraint(equalTo: tableView.widthAnchor, multiplier: 0.3),
            loadButton.bottomAnchor.constraint(equalTo: menuView.bottomAnchor),
            overwriteButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 8),
            overwriteButton.leadingAnchor.constraint(equalTo: loadButton.trailingAnchor),
            overwriteButton.trailingAnchor.constraint(equalTo: saveAsButton.leadingAnchor),
            overwriteButton.bottomAnchor.constraint(equalTo: menuView.bottomAnchor),
            saveAsButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 8),
            saveAsButton.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            saveAsButton.widthAnchor.constraint(equalTo: menuView.widthAnchor, multiplier: 0.3),
            saveAsButton.bottomAnchor.constraint(equalTo: menuView.bottomAnchor)
        ])
        
        reloadColors()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setButtonStates()
    }
    
    func setButtonStates() {
        let hasSelectedRow = self.tableView.indexPathForSelectedRow != nil
        loadButton.isEnabled = hasSelectedRow
        overwriteButton.isEnabled = hasSelectedRow
    }
    
    func loadProfileNames() {
        profileNames.removeAll()
        if let names = self.folioReader.delegate?.folioReaderPreferenceProvider?(self.folioReader).preference(listProfile: nil) {
            profileNames.append(contentsOf: names.sorted(by: { lhs, rhs in
                if lhs == "Default" {
                    return true
                }
                if rhs == "Default" {
                    return false
                }
                return lhs < rhs
            }))
        }
    }
    
    override func layoutSubviews(frame: CGRect) {
        
    }
    
    
    // MARK: - Gestures
    @objc func tapGesture() {
        dismiss() {
            self.folioReader.readerCenter?.lastMenuSelectedIndex = 4
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
    
}

extension FolioReaderProfileMenu: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 32
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setButtonStates()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        setButtonStates()
    }
}

extension FolioReaderProfileMenu: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profileNames.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kReuseCellIdentifier, for: indexPath)
        
        if let label = cell.viewWithTag(123) as? UILabel {
            label.text = profileNames[indexPath.row]
        } else {
            let label = UILabel()
            label.tag = 123
            label.frame = .init(x: 20, y: 4, width: cell.contentView.frame.width - 20, height: 24)
            label.text = profileNames[indexPath.row]
            label.textColor = .black
            cell.contentView.addSubview(label)
        }
        
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.backgroundColor = .clear
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let profileName = profileNames[safe: indexPath.row],
                  let provider = self.folioReader.delegate?.folioReaderPreferenceProvider?(self.folioReader)
            else { return }
            
            provider.preference(removeProfile: profileName)
            
            loadProfileNames()
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        } else {
            return true
        }
    }
}

extension FolioReaderProfileMenu {
    @objc func loadButtonAction(_ sender: UIButton?) {
        folioLogger("load")
        guard let provider = self.folioReader.delegate?.folioReaderPreferenceProvider?(self.folioReader) else { return }
        guard let selectedIndex = self.tableView.indexPathForSelectedRow,
              let profileName = profileNames[safe: selectedIndex.row]
        else { return }
        
        provider.preference(loadProfile: profileName)
        
        self.folioReader.readerCenter?.collectionView.visibleCells.forEach {
            guard let page = $0 as? FolioReaderPage else { return }
            
            page.webView?.isHidden = true
            page.layoutAdapting = true
            page.webView?.reload()
        }
        
        self.dismiss()
    }
    
    @objc func overwriteButtonAction(_ sender: UIButton?) {
        guard let provider = self.folioReader.delegate?.folioReaderPreferenceProvider?(self.folioReader) else { return }
        guard let selectedIndex = self.tableView.indexPathForSelectedRow,
              let profileName = profileNames[safe: selectedIndex.row]
        else { return }
        
        provider.preference(saveProfile: profileName)
        
        self.tableView.deselectRow(at: selectedIndex, animated: true)
    }
    
    @objc func saveasButtonAction(_ sender: UIButton?) {
        folioLogger("save as")
        
        guard let provider = self.folioReader.delegate?.folioReaderPreferenceProvider?(self.folioReader) else { return }
        
        if let bookTitle = self.folioReader.readerCenter?.book.title ?? self.folioReader.readerCenter?.book.name ?? self.folioReader.readerConfig?.identifier {
            provider.preference(saveProfile: "Based on \(bookTitle)")
        } else {
            var i = 1
            while( profileNames.contains("New Profile #\(i)") ) {
                i+=1
            }
            provider.preference(saveProfile: "New Profile #\(i)")
        }
        
        loadProfileNames()
        self.tableView.reloadData()
    }
}

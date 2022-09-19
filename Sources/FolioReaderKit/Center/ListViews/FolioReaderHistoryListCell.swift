//
//  FolioReaderHistoryListCell.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 07/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

class FolioReaderHistoryListCell: UITableViewCell {
    let indexLabel = UILabel()
    let indexPercent = UILabel()
    let indexToc = UILabel()
    let indexSpine = UILabel()
    
    let dateFormatter = DateFormatter()
    let percentFormatter = NumberFormatter()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        percentFormatter.maximumFractionDigits = 1
        percentFormatter.minimumFractionDigits = 1
        percentFormatter.numberStyle = .percent
        
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        self.contentView.addSubview(self.indexLabel)
        self.contentView.addSubview(self.indexPercent)
        self.contentView.addSubview(self.indexToc)
        self.contentView.addSubview(self.indexSpine)
    }

    func setup(withConfiguration readerConfig: FolioReaderConfig) {
        self.indexLabel.lineBreakMode = .byWordWrapping
        self.indexLabel.numberOfLines = 2
        self.indexLabel.translatesAutoresizingMaskIntoConstraints = false
        self.indexLabel.textColor = readerConfig.menuTextColor
        self.indexLabel.textAlignment = .right

        self.indexPercent.lineBreakMode = .byWordWrapping
        self.indexPercent.numberOfLines = 1
        self.indexPercent.translatesAutoresizingMaskIntoConstraints = false
        self.indexPercent.textColor = readerConfig.menuTextColor
        self.indexPercent.textAlignment = .right
        
        self.indexToc.lineBreakMode = .byWordWrapping
        self.indexToc.numberOfLines = 1
        self.indexToc.translatesAutoresizingMaskIntoConstraints = false
        self.indexToc.textColor = readerConfig.menuTextColor

        self.indexSpine.lineBreakMode = .byWordWrapping
        self.indexSpine.numberOfLines = 1
        self.indexSpine.translatesAutoresizingMaskIntoConstraints = false
        self.indexSpine.textColor = readerConfig.menuTextColor
        
        // Configure cell contraints
        var constraints = [NSLayoutConstraint]()
        let views = ["label": self.indexLabel, "percent": self.indexPercent, "toc": self.indexToc, "spine": self.indexSpine]
        
        NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[spine]-[label(>=50,<=200)]-15-|", options: [], metrics: nil, views: views).forEach {
            constraints.append($0 as NSLayoutConstraint)
        }
        NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[toc]-[percent(>=50,<=100)]-15-|", options: [], metrics: nil, views: views).forEach {
            constraints.append($0 as NSLayoutConstraint)
        }
        
        NSLayoutConstraint.constraints(withVisualFormat: "V:|-[spine]-[toc]-|", options: [], metrics: nil, views: views).forEach {
            constraints.append($0 as NSLayoutConstraint)
        }
        NSLayoutConstraint.constraints(withVisualFormat: "V:|-6-[label]-4-[percent]-6-|", options: [], metrics: nil, views: views).forEach {
            constraints.append($0 as NSLayoutConstraint)
        }
        
        self.contentView.addConstraints(constraints)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }
    
    func setPercentValue(_ value: Double) {
        self.indexPercent.text = percentFormatter.string(from: NSNumber(value: value))
    }
    
    func setSpineDate(_ date: Date) {
        self.indexSpine.text = dateFormatter.string(from: date)
    }
    func setLabelDate(_ date: Date) {
        self.indexLabel.text = dateFormatter.string(from: date)
    }
}

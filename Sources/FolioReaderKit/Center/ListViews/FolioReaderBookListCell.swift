//
//  FolioReaderBookListCell.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 07/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

class FolioReaderBookListCell: UITableViewCell {
    let indexLabel = UILabel()
    let positionLabel = UILabel()
    let percentageLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    func setup(withConfiguration readerConfig: FolioReaderConfig) {

        self.indexLabel.lineBreakMode = .byWordWrapping
        self.indexLabel.numberOfLines = 0
        self.indexLabel.translatesAutoresizingMaskIntoConstraints = false
        self.indexLabel.textColor = readerConfig.menuTextColor

        self.positionLabel.lineBreakMode = .byWordWrapping
        self.positionLabel.numberOfLines = 0
        self.positionLabel.translatesAutoresizingMaskIntoConstraints = false
        self.positionLabel.textColor = readerConfig.menuTextColor
        self.positionLabel.textAlignment = .right
        
        self.percentageLabel.lineBreakMode = .byWordWrapping
        self.percentageLabel.numberOfLines = 0
        self.percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        self.percentageLabel.textColor = readerConfig.menuTextColor
        self.percentageLabel.textAlignment = .right
        
        self.contentView.addSubview(self.indexLabel)
        self.contentView.addSubview(self.positionLabel)
        self.contentView.addSubview(self.percentageLabel)

        // Configure cell contraints
        var constraints = [NSLayoutConstraint]()
        let views = ["label": self.indexLabel, "pos": self.positionLabel, "percent": self.percentageLabel]
        
        NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[label]-[pos]-15-|", options: [], metrics: nil, views: views).forEach {
            constraints.append($0 as NSLayoutConstraint)
        }
        
        NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[percent]-15-|", options: [], metrics: nil, views: views).forEach {
            constraints.append($0 as NSLayoutConstraint)
        }
        
        NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[label]-16-|", options: [], metrics: nil, views: views).forEach {
            constraints.append($0 as NSLayoutConstraint)
        }
        
        NSLayoutConstraint.constraints(withVisualFormat: "V:|-[pos]-[percent]-|", options: [], metrics: nil, views: views).forEach {
            constraints.append($0 as NSLayoutConstraint)
        }
        
        self.contentView.addConstraints(constraints)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // As the `setup` is called at each reuse, make sure the label is added only once to the view hierarchy.
        self.indexLabel.removeFromSuperview()
        self.positionLabel.removeFromSuperview()
    }
}

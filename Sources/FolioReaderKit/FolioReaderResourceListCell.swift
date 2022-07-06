//
//  FolioReaderResourceListCell.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 07/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

class FolioReaderResourceListCell: UITableViewCell {
    let indexLabel = UILabel()
    let indexSize = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    func setup(withConfiguration readerConfig: FolioReaderConfig) {
        self.indexLabel.lineBreakMode = .byWordWrapping
        self.indexLabel.numberOfLines = 0
        self.indexLabel.translatesAutoresizingMaskIntoConstraints = false
        self.indexLabel.textColor = readerConfig.menuTextColor

        self.indexSize.lineBreakMode = .byWordWrapping
        self.indexSize.numberOfLines = 1
        self.indexSize.translatesAutoresizingMaskIntoConstraints = false
        self.indexSize.textColor = readerConfig.menuTextColor
        self.indexSize.textAlignment = .right
        
        self.contentView.addSubview(self.indexLabel)
        self.contentView.addSubview(self.indexSize)
        
        // Configure cell contraints
        var constraints = [NSLayoutConstraint]()
        let views = ["label": self.indexLabel, "size": self.indexSize]
        
        NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[label]-[size(>=50,<=100)]-15-|", options: [], metrics: nil, views: views).forEach {
            constraints.append($0 as NSLayoutConstraint)
        }
        
        NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[label]-16-|", options: [], metrics: nil, views: views).forEach {
            constraints.append($0 as NSLayoutConstraint)
        }
        
        NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[size]-16-|", options: [], metrics: nil, views: views).forEach {
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
        self.indexSize.removeFromSuperview()
    }
}

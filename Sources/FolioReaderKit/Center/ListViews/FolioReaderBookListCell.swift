//
//  FolioReaderBookListCell.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 07/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

class FolioReaderBookListCell: UICollectionViewCell {
    let coverImage = UIImageView()
    let titleLabel = UILabel()
    let positionLabel = UILabel()
    let percentageLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.coverImage)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.positionLabel)
        self.contentView.addSubview(self.percentageLabel)
    }
    
    func setup(withConfiguration readerConfig: FolioReaderConfig) {

        self.titleLabel.frame = .init(x: 8, y: 8, width: self.frame.width - 16, height: 32)
        self.titleLabel.font = UIFont(name: "Avenir", size: 19.0)
        self.titleLabel.adjustsFontSizeToFitWidth = true
        self.titleLabel.textAlignment = .center
        self.titleLabel.lineBreakMode = .byWordWrapping
        self.titleLabel.numberOfLines = 1
        self.titleLabel.textColor = readerConfig.menuTextColor

        self.coverImage.frame = .init(x: 16, y: 40, width: self.frame.width - 32, height: self.frame.height - 80)
        
        self.positionLabel.frame = .init(
            x: 16,
            y: self.coverImage.frame.maxY + 2,
            width: self.frame.width - 32 - 80,
            height: 28
        )
        self.positionLabel.lineBreakMode = .byWordWrapping
        self.positionLabel.numberOfLines = 0
//        self.positionLabel.translatesAutoresizingMaskIntoConstraints = false
        self.positionLabel.textColor = readerConfig.menuTextColor
        self.positionLabel.textAlignment = .left
        
        self.percentageLabel.frame = .init(
            x: self.frame.width - 16 - 80,
            y: self.coverImage.frame.maxY + 2,
            width: 80,
            height: 28
        )
        self.percentageLabel.lineBreakMode = .byWordWrapping
        self.percentageLabel.numberOfLines = 0
//        self.percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        self.percentageLabel.textColor = readerConfig.menuTextColor
        self.percentageLabel.textAlignment = .right
        
        
        // Configure cell contraints
//        var constraints = [NSLayoutConstraint]()
//        let views = ["cover": self.coverImage, "title": self.titleLabel, "pos": self.positionLabel, "percent": self.percentageLabel]
//
//        NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[cover]-15-|", options: [], metrics: nil, views: views).forEach {
//            constraints.append($0 as NSLayoutConstraint)
//        }
//
//        NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[title]-15-|", options: [], metrics: nil, views: views).forEach {
//            constraints.append($0 as NSLayoutConstraint)
//        }
//
//        NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[pos]-[percent]-15-|", options: [], metrics: nil, views: views).forEach {
//            constraints.append($0 as NSLayoutConstraint)
//        }
//
//        NSLayoutConstraint.constraints(withVisualFormat: "V:|-[cover]-[title]-[pos]-|", options: [], metrics: nil, views: views).forEach {
//            constraints.append($0 as NSLayoutConstraint)
//        }
//        NSLayoutConstraint.constraints(withVisualFormat: "V:|-[cover]-[title]-[percent]-|", options: [], metrics: nil, views: views).forEach {
//            constraints.append($0 as NSLayoutConstraint)
//        }
//        self.contentView.addConstraints(constraints)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // As the `setup` is called at each reuse, make sure the label is added only once to the view hierarchy.
//        self.coverImage.removeFromSuperview()
//        self.titleLabel.removeFromSuperview()
//        self.positionLabel.removeFromSuperview()
//        self.percentageLabel.removeFromSuperview()
    }
}

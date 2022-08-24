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
        
        self.titleLabel.font = UIFont(name: "Avenir", size: 19.0)
        self.titleLabel.adjustsFontSizeToFitWidth = true
        self.titleLabel.textAlignment = .center
        self.titleLabel.lineBreakMode = .byWordWrapping
        self.titleLabel.numberOfLines = 1

        self.coverImage.contentMode = .scaleAspectFit

        self.positionLabel.lineBreakMode = .byWordWrapping
        self.positionLabel.numberOfLines = 1
        self.positionLabel.textAlignment = .left
        
        self.percentageLabel.lineBreakMode = .byWordWrapping
        self.percentageLabel.numberOfLines = 1
        self.percentageLabel.textAlignment = .right

        self.contentView.addSubview(self.coverImage)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.positionLabel)
        self.contentView.addSubview(self.percentageLabel)
    }
    
    func setup(withConfiguration readerConfig: FolioReaderConfig) {
        self.titleLabel.frame = .init(x: 8, y: 8, width: self.frame.width - 16, height: 32)
        self.titleLabel.textColor = readerConfig.menuTextColor

        self.coverImage.frame = .init(x: 16, y: 40, width: self.frame.width - 32, height: self.frame.height - 80)
        
        self.positionLabel.frame = .init(
            x: 16,
            y: self.coverImage.frame.maxY + 2,
            width: self.frame.width - 32 - 80,
            height: 28
        )
        self.positionLabel.textColor = readerConfig.menuTextColor
        
        self.percentageLabel.frame = .init(
            x: self.frame.width - 16 - 80,
            y: self.coverImage.frame.maxY + 2,
            width: 80,
            height: 28
        )
        self.percentageLabel.textColor = readerConfig.menuTextColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }
}

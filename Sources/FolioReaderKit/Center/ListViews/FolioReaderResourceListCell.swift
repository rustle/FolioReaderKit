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
    let indexToc = UILabel()
    let indexSpine = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    func setup(withConfiguration readerConfig: FolioReaderConfig) {
        self.indexLabel.lineBreakMode = .byWordWrapping
        self.indexLabel.numberOfLines = 2
        self.indexLabel.translatesAutoresizingMaskIntoConstraints = false
        self.indexLabel.textColor = readerConfig.menuTextColor
        self.indexLabel.textAlignment = .right

        self.indexSize.lineBreakMode = .byWordWrapping
        self.indexSize.numberOfLines = 1
        self.indexSize.translatesAutoresizingMaskIntoConstraints = false
        self.indexSize.textColor = readerConfig.menuTextColor
        self.indexSize.textAlignment = .right
        
        self.indexToc.lineBreakMode = .byWordWrapping
        self.indexToc.numberOfLines = 1
        self.indexToc.translatesAutoresizingMaskIntoConstraints = false
        self.indexToc.textColor = readerConfig.menuTextColor

        self.indexSpine.lineBreakMode = .byWordWrapping
        self.indexSpine.numberOfLines = 1
        self.indexSpine.translatesAutoresizingMaskIntoConstraints = false
        self.indexSpine.textColor = readerConfig.menuTextColor
        
        self.contentView.addSubview(self.indexLabel)
        self.contentView.addSubview(self.indexSize)
        self.contentView.addSubview(self.indexToc)
        self.contentView.addSubview(self.indexSpine)

        // Configure cell contraints
        var constraints = [NSLayoutConstraint]()
        let views = ["label": self.indexLabel, "size": self.indexSize, "toc": self.indexToc, "spine": self.indexSpine]
        
        NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[spine]-[label(>=50,<=200)]-15-|", options: [], metrics: nil, views: views).forEach {
            constraints.append($0 as NSLayoutConstraint)
        }
        NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[toc]-[size(>=50,<=100)]-15-|", options: [], metrics: nil, views: views).forEach {
            constraints.append($0 as NSLayoutConstraint)
        }
        
        NSLayoutConstraint.constraints(withVisualFormat: "V:|-[spine]-[toc]-|", options: [], metrics: nil, views: views).forEach {
            constraints.append($0 as NSLayoutConstraint)
        }
        NSLayoutConstraint.constraints(withVisualFormat: "V:|-6-[label]-4-[size]-6-|", options: [], metrics: nil, views: views).forEach {
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
        self.indexToc.removeFromSuperview()
        self.indexSpine.removeFromSuperview()
    }
}

//
//  FolioReaderCenterLayout.swift
//  Example
//
//  Created by liyi on 2021/5/27.
//  Copyright © 2021 FolioReader. All rights reserved.
//

import Foundation
import UIKit

class FolioReaderCenterLayout : UICollectionViewFlowLayout {
    
    var contentSize = CGSize()

    var layoutAttributes = [UICollectionViewLayoutAttributes]()
    
//    open override var collectionViewContentSize: CGSize {
//        return contentSize
//    }
    
    override func prepare() {
        super.prepare()
        
        guard let collectionView = self.collectionView else { return }
        
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        
//        self.itemSize = collectionView.bounds.inset(by: collectionView.layoutMargins).size
//        self.sectionInset = UIEdgeInsets(top: 0, left: self.minimumInteritemSpacing, bottom: 0, right: 0)
//        self.sectionInsetReference = .fromSafeArea
        self.itemSize = collectionView.bounds.size
//        self.itemSize = CGSize(width: itemSize.width, height: itemSize.height - 20)
        
        //self.scrollDirection = .horizontal
        
//        contentSize = CGSize(
//            width: collectionView.frame.width * CGFloat(collectionView.numberOfItems(inSection: 0)),
//            height: collectionView.frame.height
//        )
        
        print("PREPAREROTATE collectionViewContentSize=\(collectionViewContentSize.debugDescription) w=\(collectionViewContentSize.width) h=\(collectionViewContentSize.height) collectionView.bounds=\(collectionView.bounds) w=\(collectionView.bounds.width) h=\(collectionView.bounds.height) collectionView.frame=\(collectionView.frame) numberOfItems=\(numberOfItems)")
        
        layoutAttributes.removeAll()
        
    }
    
//    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
//
//        return layoutAttributes[indexPath.row]
//    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        print("PROPOSEROTATE \(proposedContentOffset)")
        return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        print("PROPOSEROTATE \(proposedContentOffset)")
        return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        
        guard let collectionView = collectionView else {
            return false
        }
        
        print("SHOULDTRANSROTATE oldBounds=\(collectionView.bounds) newBounds=\(newBounds)")
        
        let oldBounds = collectionView.bounds
        guard oldBounds.size != newBounds.size else { return false }
        
        self.itemSize = newBounds.size
        self.estimatedItemSize = newBounds.size
        collectionView.setContentOffset(
            CGPoint(
                x: oldBounds.minX / oldBounds.width * newBounds.width,
                y: oldBounds.minY / oldBounds.height * newBounds.height
            ), animated: false)
        
        return true
    }
}

//
//  LastReadPosition.swift
//  FolioReaderKit
//
//  Created by Peter on 2022/8/2.
//  Copyright © 2022 FolioReader. All rights reserved.
//

import Foundation

@objc open class FolioReaderLastReadPosition: NSObject {
    open var deviceId: String!
    open var pageNumber: Int!   //counting from 1
    open var cfi: String!
    
    open var structuralStyle: FolioReaderStructuralStyle = .atom
    open var positionTrackingStyle: FolioReaderPositionTrackingStyle = .linear
}

public enum FolioReaderStructuralStyle: Int, CaseIterable {
    case atom = 0
    case bundle = 1
    case item = 9
    
    var description: String {
        switch (self) {
        case .atom:
            return "Linear Reading"
        case .bundle:
            return "Bundle/Collected"
        case .item:
            return "Independent Items"
        }
    }
    
    var segmentIndex: Int {
        switch (self) {
        case .atom:
            return 0
        case .bundle:
            return 1
        case .item:
            return 2
        }
    }
    
}

public enum FolioReaderPositionTrackingStyle: Int, CaseIterable {
    case linear = 0
    case level1 = 1
    case level2 = 2
    case level3 = 3
    case levelMax = 9
    
    var description: String {
        switch (self) {
        case .linear:
            return "Linear"
        case .level1, .level2, .level3:
            return "Level \(self.rawValue)"
        case .levelMax:
            return "Per Page"
        }
    }
}

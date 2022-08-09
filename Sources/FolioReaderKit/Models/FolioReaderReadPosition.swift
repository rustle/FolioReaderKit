//
//  LastReadPosition.swift
//  FolioReaderKit
//
//  Created by Peter on 2022/8/2.
//  Copyright © 2022 FolioReader. All rights reserved.
//

import Foundation

@objc open class FolioReaderReadPosition: NSObject {
    
    public let deviceId: String
    public let structuralStyle: FolioReaderStructuralStyle
    public let positionTrackingStyle: FolioReaderPositionTrackingStyle
    public let structuralRootPageNumber: Int
    
    public let pageNumber: Int   //counting from 1
    public let cfi: String
    
    open var maxPage: Int = 1
    open var pageOffset: CGPoint = .zero
    
    open var chapterProgress: Double = .zero
    open var chapterName: String = "Untitled Chapter"
    open var bookProgress: Double = .zero
    open var bookName: String = ""
    open var bundleProgress: Double = .zero
    
    open var epoch: Date = Date()
    
    open var takePrecedence: Bool = false
    
    public init(deviceId: String, structuralStyle: FolioReaderStructuralStyle, positionTrackingStyle: FolioReaderPositionTrackingStyle, structuralRootPageNumber: Int, pageNumber: Int, cfi: String) {
        self.deviceId = deviceId
        self.structuralStyle = structuralStyle
        self.positionTrackingStyle = positionTrackingStyle
        self.structuralRootPageNumber = structuralRootPageNumber
        self.pageNumber = pageNumber
        self.cfi = cfi
    }
}

public enum FolioReaderStructuralStyle: Int, CaseIterable {
    case atom = 0
    case bundle = 1
    case topic = 9
    
    var description: String {
        switch (self) {
        case .atom:
            return "Linear Reading"
        case .bundle:
            return "Bundle/Collected"
        case .topic:
            return "Independent Items"
        }
    }
    
    var segmentIndex: Int {
        switch (self) {
        case .atom:
            return 0
        case .bundle:
            return 1
        case .topic:
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

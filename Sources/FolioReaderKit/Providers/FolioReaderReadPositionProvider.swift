//
//  FolioReaderHighlightProvider.swift
//  AEXML
//
//  Created by 京太郎 on 2021/9/23.
//

import Foundation

@objc public protocol FolioReaderReadPositionProvider: AnyObject {

    /**
        get latest one, considing precedence
     */
    @objc func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String) -> FolioReaderReadPosition?
    
    @objc func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String, by rootPageNumber: Int) -> FolioReaderReadPosition?
    
    @objc func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String, set readPosition: FolioReaderReadPosition, completion: Completion?)
    
    @objc func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String, remove readPosition: FolioReaderReadPosition)
    
    @objc func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String, getById deviceId: String) -> [FolioReaderReadPosition]
    
    @objc func folioReaderReadPosition(_ folioReader: FolioReader, allByBookId bookId: String) -> [FolioReaderReadPosition]
    
    @objc func folioReaderReadPosition(_ folioReader: FolioReader) -> [FolioReaderReadPosition]
        
}

public class FolioReaderNaiveReadPositionProvider: FolioReaderReadPositionProvider {
    
    var positions : [String: [String: FolioReaderReadPosition]] = [:]
    
    public func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String) -> FolioReaderReadPosition? {
        return positions.flatMap { $0.value }.compactMap { $0.value }.max {
            if $0.takePrecedence == $1.takePrecedence {
                return $0.epoch < $1.epoch
            }
            return $1.takePrecedence
        }
    }
    
    public func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String, by rootTocPageNumner: Int) -> FolioReaderReadPosition? {
        return self.positions[bookId]?.filter {
            $0.value.structuralStyle == folioReader.structuralStyle
            && $0.value.positionTrackingStyle == folioReader.structuralTrackingTocLevel
            && $0.value.structuralRootPageNumber == rootTocPageNumner
        }.first?.value
    }
    
    public func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String, set lastReadPosition: FolioReaderReadPosition, completion: Completion?) {
        if self.positions[bookId] == nil {
            self.positions[bookId] = [:]
        }
        self.positions[bookId]?[lastReadPosition.deviceId] = lastReadPosition
    }
    
    public func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String, remove readPosition: FolioReaderReadPosition) {
        self.positions[bookId]?.removeValue(forKey: readPosition.deviceId)
    }
    
    public func folioReaderReadPosition(_ folioReader: FolioReader, bookId: String, getById deviceId: String) -> [FolioReaderReadPosition] {
        if let position = self.positions[bookId]?[deviceId] {
            return [position]
        } else {
            return []
        }
    }
    
    public func folioReaderReadPosition(_ folioReader: FolioReader, allByBookId bookId: String) -> [FolioReaderReadPosition] {
        return self.positions[bookId]?.values.map { $0 } ?? []
    }
    
    public func folioReaderReadPosition(_ folioReader: FolioReader) -> [FolioReaderReadPosition] {
        return self.positions.reduce(into: []) { partialResult, bookPositions in
            partialResult.append(contentsOf: bookPositions.value.values)
        }
    }
    
    public init() {
        
    }
    
}

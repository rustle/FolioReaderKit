//
//  FolioReaderHighlightProvider.swift
//  AEXML
//
//  Created by 京太郎 on 2021/9/23.
//

import Foundation

@objc public protocol FolioReaderLastReadPositionProvider: AnyObject {

    @objc func folioReaderLastReadPosition(_ folioReader: FolioReader, bookId: String, set lastReadPosition: FolioReaderLastReadPosition, completion: Completion?)
    
    @objc func folioReaderLastReadPosition(_ folioReader: FolioReader, bookId: String, remove deviceId: String)
    
    @objc func folioReaderLastReadPosition(_ folioReader: FolioReader, bookId: String, getById deviceId: String) -> [FolioReaderLastReadPosition]
    
    @objc func folioReaderLastReadPosition(_ folioReader: FolioReader, allByBookId bookId: String) -> [FolioReaderLastReadPosition]
    
    @objc func folioReaderLastReadPosition(_ folioReader: FolioReader) -> [FolioReaderLastReadPosition]
        
}

public class FolioReaderDummyLastReadPositionProvider: FolioReaderLastReadPositionProvider {
    var positions : [String: [String: FolioReaderLastReadPosition]] = [:]
    
    public func folioReaderLastReadPosition(_ folioReader: FolioReader, bookId: String, set lastReadPosition: FolioReaderLastReadPosition, completion: Completion?) {
        if self.positions[bookId] == nil {
            self.positions[bookId] = [:]
        }
        self.positions[bookId]?[lastReadPosition.deviceId] = lastReadPosition
    }
    
    public func folioReaderLastReadPosition(_ folioReader: FolioReader, bookId: String, remove deviceId: String) {
        self.positions[bookId]?.removeValue(forKey: deviceId)
    }
    
    public func folioReaderLastReadPosition(_ folioReader: FolioReader, bookId: String, getById deviceId: String) -> [FolioReaderLastReadPosition] {
        if let position = self.positions[bookId]?[deviceId] {
            return [position]
        } else {
            return []
        }
    }
    
    public func folioReaderLastReadPosition(_ folioReader: FolioReader, allByBookId bookId: String) -> [FolioReaderLastReadPosition] {
        return self.positions[bookId]?.values.map { $0 } ?? []
    }
    
    public func folioReaderLastReadPosition(_ folioReader: FolioReader) -> [FolioReaderLastReadPosition] {
        return self.positions.reduce(into: []) { partialResult, bookPositions in
            partialResult.append(contentsOf: bookPositions.value.values)
        }
    }
    
    public init() {
        
    }
    
}

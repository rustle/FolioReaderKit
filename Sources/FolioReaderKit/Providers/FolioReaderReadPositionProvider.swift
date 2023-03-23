//
//  FolioReaderHighlightProvider.swift
//  AEXML
//
//  Created by 京太郎 on 2021/9/23.
//

import Foundation

public protocol FolioReaderReadPositionProvider: AnyObject {
    /**
        get latest one, considing precedence
     */
    func folioReaderReadPosition(
        _ folioReader: FolioReader,
        bookId: String
    ) -> FolioReaderReadPosition?

    func folioReaderReadPosition(
        _ folioReader: FolioReader,
        bookId: String,
        by rootPageNumber: Int
    ) -> FolioReaderReadPosition?

    func folioReaderReadPosition(
        _ folioReader: FolioReader,
        bookId: String,
        set readPosition: FolioReaderReadPosition,
        completion: Completion?
    )

    func folioReaderReadPosition(
        _ folioReader: FolioReader,
        bookId: String,
        remove readPosition: FolioReaderReadPosition
    )

    func folioReaderReadPosition(
        _ folioReader: FolioReader,
        bookId: String,
        getById deviceId: String
    ) -> [FolioReaderReadPosition]
    
    func folioReaderReadPosition(
        _ folioReader: FolioReader,
        allByBookId bookId: String
    ) -> [FolioReaderReadPosition]

    func folioReaderReadPosition(_ folioReader: FolioReader) -> [FolioReaderReadPosition]

    func folioReaderPositionHistory(
        _ folioReader: FolioReader,
        bookId: String
    ) -> [FolioReaderReadPositionHistory]

    //func folioReaderPositionHistory(_ folioReader: FolioReader, bookId: String, start readPosition: FolioReaderReadPosition)

    //func folioReaderPositionHistory(_ folioReader: FolioReader, bookId: String, finish readPosition: FolioReaderReadPosition)

    //func folioReaderPositionHistory(_ folioReader: FolioReader, bookId: String, remove readPosition: FolioReaderReadPositionHistory)
}

public class FolioReaderNaiveReadPositionProvider: FolioReaderReadPositionProvider {
    var positions : [String: [String: FolioReaderReadPosition]] = [:]
    var history: [FolioReaderReadPositionHistory] = []

    public func folioReaderReadPosition(
        _ folioReader: FolioReader,
        bookId: String
    ) -> FolioReaderReadPosition? {
        positions.flatMap { $0.value }.compactMap { $0.value }.max {
            if $0.takePrecedence == $1.takePrecedence {
                return $0.epoch < $1.epoch
            }
            return $1.takePrecedence
        }
    }
    
    public func folioReaderReadPosition(
        _ folioReader: FolioReader,
        bookId: String,
        by rootTocPageNumner: Int
    ) -> FolioReaderReadPosition? {
        positions[bookId]?.filter {
            $0.value.structuralStyle == folioReader.structuralStyle
            && $0.value.positionTrackingStyle == folioReader.structuralTrackingTocLevel
            && $0.value.structuralRootPageNumber == rootTocPageNumner
        }.first?.value
    }
    
    public func folioReaderReadPosition(
        _ folioReader: FolioReader,
        bookId: String,
        set lastReadPosition: FolioReaderReadPosition,
        completion: Completion?
    ) {
        if positions[bookId] == nil {
            positions[bookId] = [:]
        }
        positions[bookId]?[lastReadPosition.deviceId] = lastReadPosition
    }
    
    public func folioReaderReadPosition(
        _ folioReader: FolioReader,
        bookId: String,
        remove readPosition: FolioReaderReadPosition
    ) {
        positions[bookId]?.removeValue(forKey: readPosition.deviceId)
    }
    
    public func folioReaderReadPosition(
        _ folioReader: FolioReader,
        bookId: String,
        getById deviceId: String
    ) -> [FolioReaderReadPosition] {
        if let position = positions[bookId]?[deviceId] {
            return [position]
        } else {
            return []
        }
    }
    
    public func folioReaderReadPosition(
        _ folioReader: FolioReader,
        allByBookId bookId: String
    ) -> [FolioReaderReadPosition] {
        positions[bookId]?.values.map { $0 } ?? []
    }
    
    public func folioReaderReadPosition(_ folioReader: FolioReader) -> [FolioReaderReadPosition] {
        positions.reduce(into: []) { partialResult, bookPositions in
            partialResult.append(contentsOf: bookPositions.value.values)
        }
    }
    
    public init() {}
    
    public func folioReaderPositionHistory(
        _ folioReader: FolioReader,
        bookId: String
    ) -> [FolioReaderReadPositionHistory] {
        history
    }
    
}

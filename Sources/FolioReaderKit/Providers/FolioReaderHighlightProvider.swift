//
//  FolioReaderHighlightProvider.swift
//  AEXML
//
//  Created by 京太郎 on 2021/9/23.
//

import Foundation

@objc public protocol FolioReaderHighlightProvider: class {

    /// Save a Highlight with completion block
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - completion: Completion block.
    @objc func folioReaderHighlight(_ folioReader: FolioReader, added highlight: Highlight, completion: Completion?)
    
    /// Remove a Highlight by ID
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - highlightId: The ID to be removed
    @objc func folioReaderHighlight(_ folioReader: FolioReader, removedId highlightId: String)
    
    /// Update a Highlight by ID
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - highlightId: The ID to be removed
    ///   - type: The `HighlightStyle`
    @objc func folioReaderHighlight(_ folioReader: FolioReader, updateById highlightId: String, type style: HighlightStyle)
    
    /// Return a Highlight by ID
    ///
    /// - Parameter:
    ///   - readerConfig: Current folio reader configuration.
    ///   - highlightId: The ID to be removed
    ///   - page: Page number
    /// - Returns: Return a Highlight
    @objc func folioReaderHighlight(_ folioReader: FolioReader, getById highlightId: String) -> Highlight?
    
    /// Return a list of Highlights with a given ID
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - bookId: Book ID
    ///   - page: Page number
    /// - Returns: Return a list of Highlights
    @objc func folioReaderHighlight(_ folioReader: FolioReader, allByBookId bookId: String, andPage page: NSNumber?) -> [Highlight]
    
    /// Return all Highlights
    ///
    /// - Parameter readerConfig: - readerConfig: Current folio reader configuration.
    /// - Returns: Return all Highlights
    @objc func folioReaderHighlight(_ folioReader: FolioReader) -> [Highlight]
    
    @objc func folioReaderHighlight(_ folioReader: FolioReader, saveNoteFor highlight: Highlight)
    
}

public class FolioReaderDummyHighlightProvider: FolioReaderHighlightProvider {
    
    public init() {
        
    }
    public func folioReaderHighlight(_ folioReader: FolioReader, added highlight: Highlight, completion: Completion?) {
        
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, removedId highlightId: String) {
        
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, updateById highlightId: String, type style: HighlightStyle) {
        
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, getById highlightId: String) -> Highlight? {
        return nil
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, allByBookId bookId: String, andPage page: NSNumber?) -> [Highlight] {
        return []
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader) -> [Highlight] {
        return []
    }
    
    public func folioReaderHighlight(_ folioReader: FolioReader, saveNoteFor highlight: Highlight) {
        
    }
}

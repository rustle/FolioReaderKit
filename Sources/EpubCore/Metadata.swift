//
//  Metadata.swift
//  EpubCore
//
//  Created by Heberti Almeida on 04/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//  Copyright (c) 2023 Doug Russell. All rights reserved.
//

import Foundation

/**
 Manages book metadata.
 */
final public class Metadata {
    public var creators = [Author]()
    public var contributors = [Author]()
    public var dates = [EventDate]()
    public var language = "en-US"
    public var titles = [String]()
    public var identifiers = [Identifier]()
    public var subjects = [String]()
    public var descriptions = [String]()
    public var publishers = [String]()
    public var format = MediaType.epub.name
    public var rights = [String]()
    public var metaAttributes = [Meta]()

    /**
     Find a book unique identifier by ID

     - parameter id: The ID
     - returns: The unique identifier of a book
     */
    public func find(identifierById id: String) -> Identifier? {
        return identifiers.filter({ $0.id == id }).first
    }

    public func find(byName name: String) -> Meta? {
        return metaAttributes.filter({ $0.name == name }).first
    }

    public func find(
        byProperty property: String,
        refinedBy: String? = nil
    ) -> Meta? {
        return metaAttributes.filter {
            if let refinedBy = refinedBy {
                return $0.property == property && $0.refines == refinedBy
            }
            return $0.property == property
        }.first
    }
}

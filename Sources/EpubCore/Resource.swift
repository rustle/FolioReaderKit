//
//  Resource.swift
//  EpubCore
//
//  Created by Heberti Almeida on 29/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//  Copyright (c) 2023 Doug Russell. All rights reserved.
//

import UIKit

final public class Resource: Hashable {
    public static func == (
        lhs: Resource,
        rhs: Resource
    ) -> Bool {
        lhs.id == rhs.id &&
        lhs.href == rhs.href
    }
    public var id: String!
    public var properties: String?
    public var mediaType: MediaType!
    public var mediaOverlay: String?
    
    public var href: String!
    public var fullHref: String!
    public var size: Int?
    public var spineIndices = [Int]()

    public func basePath() -> String! {
        if href == nil || href.isEmpty { return nil }
        var paths = fullHref.components(separatedBy: "/")
        paths.removeLast()
        return paths.joined(separator: "/")
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(href)
    }
}

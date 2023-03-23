//
//  TocReference.swift
//  EpubCore
//
//  Created by Heberti Almeida on 06/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//  Copyright (c) 2023 Doug Russell. All rights reserved.
//

import Foundation

final public class TocReference: Hashable {
    public static func == (
        lhs: TocReference,
        rhs: TocReference
    ) -> Bool {
        lhs.title == rhs.title &&
        lhs.fragmentID == rhs.fragmentID &&
        lhs.level == rhs.level
    }

    public var children: [TocReference]!

    public var title: String!
    public var resource: Resource?
    public var fragmentID: String?
    public var level: Int?
    public var parent: TocReference?
    
    public convenience init(
        title: String,
        resource: Resource?,
        fragmentID: String = "",
        level: Int = 0,
        parent: TocReference? = nil
    ) {
        self.init(title: title, resource: resource, fragmentID: fragmentID, children: [TocReference](), level: level, parent: parent)
    }

    public init(
        title: String,
        resource: Resource?,
        fragmentID: String,
        children: [TocReference],
        level: Int,
        parent: TocReference?
    ) {
        self.resource = resource
        self.title = title
        self.fragmentID = fragmentID
        self.children = children
        self.level = level
        self.parent = parent
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(fragmentID)
        hasher.combine(level)
    }
}

//
//  Meta.swift
//  EpubCore
//
//  Created by Heberti Almeida on 04/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//  Copyright (c) 2023 Doug Russell. All rights reserved.
//

import Foundation

/**
 A metadata tag data.
 */
public struct Meta {
    public var name: String?
    public var content: String?
    public var id: String?
    public var property: String?
    public var value: String?
    public var refines: String?

    public init(
        name: String? = nil,
        content: String? = nil,
        id: String? = nil,
        property: String? = nil,
        value: String? = nil,
        refines: String? = nil
    ) {
        self.name = name
        self.content = content
        self.id = id
        self.property = property
        self.value = value
        self.property = property
        self.value = value
        self.refines = refines
    }
}

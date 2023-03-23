//
//  Identifier.swift
//  EpubCore
//
//  Created by Heberti Almeida on 04/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//  Copyright (c) 2023 Doug Russell. All rights reserved.
//

import Foundation

/**
 A Book's identifier.
 */
public struct Identifier {
    public var id: String?
    public var scheme: String?
    public var value: String?

    public init(
        id: String?,
        scheme: String?,
        value: String?
    ) {
        self.id = id
        self.scheme = scheme
        self.value = value
    }
}

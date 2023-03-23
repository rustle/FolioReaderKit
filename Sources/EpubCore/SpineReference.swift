//
//  SpineReference.swift
//  EpubCore
//
//  Created by Heberti Almeida on 06/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//  Copyright (c) 2023 Doug Russell. All rights reserved.
//

import Foundation

public struct SpineReference {
    public var linear: Bool
    public var resource: Resource
    public var sizeUpTo: Int

    public init(
        resource: Resource,
        linear: Bool = true,
        sizeUpto: Int = 0
    ) {
        self.resource = resource
        self.linear = linear
        self.sizeUpTo = sizeUpto
    }
}

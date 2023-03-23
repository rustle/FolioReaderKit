//
//  Author.swift
//  EpubCore
//
//  Created by Heberti Almeida on 04/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//  Copyright (c) 2023 Doug Russell. All rights reserved.
//

/**
 Represents one of the authors of the book.
 */
public struct Author {
    public var name: String
    public var role: String
    public var fileAs: String

    init(
        name: String,
        role: String,
        fileAs: String
    ) {
        self.name = name
        self.role = role
        self.fileAs = fileAs
    }
}

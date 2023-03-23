//
//  EventDate.swift
//  EpubCore
//
//  Created by Heberti Almeida on 04/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//  Copyright (c) 2023 Doug Russell. All rights reserved.
//

import Foundation

/**
 A date and his event.
 */
public struct EventDate {
    public var date: String
    public var event: String?

    public init(
        date: String,
        event: String?
    ) {
        self.date = date
        self.event = event
    }
}

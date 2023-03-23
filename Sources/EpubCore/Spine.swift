//
//  Spine.swift
//  EpubCore
//
//  Created by Heberti Almeida on 06/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//  Copyright (c) 2023 Doug Russell. All rights reserved.
//

import Foundation

final public class Spine {
    public var pageProgressionDirection: String?
    public var spineReferences = [SpineReference]()
    public var size = 0

    public var isRtl: Bool {
        if let pageProgressionDirection = pageProgressionDirection, pageProgressionDirection == "rtl" {
            return true
        }
        return false
    }

    public func nextChapter(_ href: String) -> Resource? {
        var found = false;

        for item in spineReferences {
            if found {
                return item.resource
            }

            if item.resource.href == href {
                found = true
            }
        }
        return nil
    }
}

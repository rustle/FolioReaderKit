//
//  Smils.swift
//  EpubCore
//
//  Created by Kevin Jantzer on 12/30/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//  Copyright (c) 2015 Kevin Jantzer. All rights reserved.
//  Copyright (c) 2023 Doug Russell. All rights reserved.
//

import Foundation

/**
 Holds array of `SmilFile`
 */
final public class Smils {
    public var basePath: String!
    public var smils = [String: SmilFile]()

    /**
     Adds a smil to the smils.
     */
    public func add(_ smil: SmilFile) {
        self.smils[smil.resource.href] = smil
    }

    /**
     Gets the resource with the given href.
     */
    public func findByHref(_ href: String) -> SmilFile? {
        for smil in smils.values {
            if smil.resource.href == href {
                return smil
            }
        }
        return nil
    }

    /**
     Gets the resource with the given id.
     */
    public func findById(_ ID: String) -> SmilFile? {
        for smil in smils.values {
            if smil.resource.id == ID {
                return smil
            }
        }
        return nil
    }
}

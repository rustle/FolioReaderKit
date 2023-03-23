//
//  SmilFile.swift
//  EpubCore
//
//  Created by Kevin Jantzer on 12/30/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//  Copyright (c) 2015 Kevin Jantzer. All rights reserved.
//  Copyright (c) 2023 Doug Russell. All rights reserved.
//

import Foundation

public struct SmilFile {
    public var resource: Resource
    public var data = [SmilElement]()

    public init(resource: Resource){
        self.resource = resource;
    }

    // MARK: - shortcuts

    public func ID() -> String {
        self.resource.id;
    }

    public func href() -> String {
        self.resource.href;
    }

    // MARK: - data methods

    /**
     Returns a smil <par> tag which contains info about parallel audio and text to be played
     */
    public func parallelAudioForFragment(_ fragment: String!) -> SmilElement! {
        findParElement(forTextSrc: fragment, inData: data)
    }

    fileprivate func findParElement(forTextSrc src: String!, inData _data: [SmilElement]) -> SmilElement! {
        for el in _data {
            // if its a <par> (parallel) element and has a <text> node with the matching fragment
            if el.name == "par" && (src == nil || el.textElement().attributes["src"]?.contains(src) != false ) {
                return el

                // if its a <seq> (sequence) element, it should have children (<par>)
            } else if el.name == "seq" && el.children.count > 0 {
                let parEl = findParElement(forTextSrc: src, inData: el.children)
                if parEl != nil { return parEl }
            }
        }
        return nil
    }

    /**
     Returns a smil <par> element after the given fragment
     */
    public func nextParallelAudioForFragment(_ fragment: String) -> SmilElement! {
        findNextParElement(forTextSrc: fragment, inData: data)
    }

    fileprivate func findNextParElement(forTextSrc src: String!, inData _data: [SmilElement]) -> SmilElement! {
        var foundPrev = false
        for el in _data {
            if foundPrev { return el }

            // if its a <par> (parallel) element and has a <text> node with the matching fragment
            if el.name == "par" && (src == nil || el.textElement().attributes["src"]?.contains(src) != false) {
                foundPrev = true

                // if its a <seq> (sequence) element, it should have children (<par>)
            } else if el.name == "seq" && el.children.count > 0 {
                let parEl = findNextParElement(forTextSrc: src, inData: el.children)
                if parEl != nil { return parEl }
            }
        }
        return nil
    }

    public func childWithName(_ name: String) -> SmilElement! {
        for el in data {
            if el.name == name {
                return el
            }
        }
        return nil;
    }

    public func childrenWithNames(_ name: [String]) -> [SmilElement]! {
        var matched = [SmilElement]()
        for el in data {
            if name.contains(el.name) {
                matched.append(el)
            }
        }
        return matched;
    }

    public func childrenWithName(_ name: String) -> [SmilElement]! {
        childrenWithNames([name])
    }
}

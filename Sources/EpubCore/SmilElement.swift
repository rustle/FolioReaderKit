//
//  SmilElement.swift
//  EpubCore
//
//  Created by Kevin Jantzer on 12/30/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//  Copyright (c) 2023 Doug Russell. All rights reserved.
//

import Foundation

// Media Overlay Documentation
// http://www.idpf.org/accessibility/guidelines/content/overlays/overview.php#mo005-samp

public class SmilElement {
    public var name: String // the name of the tag: <seq>, <par>, <text>, <audio>
    public var attributes: [String: String]!
    public var children: [SmilElement]

    public init(
        name: String,
        attributes: [String:String]!
    ) {
        self.name = name
        self.attributes = attributes
        self.children = [SmilElement]()
    }

    // MARK: - Element attributes

    public func getId() -> String! {
        getAttribute("id")
    }

    public func getSrc() -> String! {
        getAttribute("src")
    }

    /**
     Returns array of Strings if `epub:type` attribute is set. An array is returned as there can be multiple types specified, seperated by a whitespace
     */
    public func getType() -> [String]! {
        let type = getAttribute("epub:type", defaultVal: "")
        return type!.components(separatedBy: " ")
    }

    /**
     Use to determine if this element matches a given type

     **Example**

     epub:type="bodymatter chapter"
     isType("bodymatter") -> true
     */
    public func isType(_ aType:String) -> Bool {
        getType().contains(aType)
    }

    public func getAttribute(_ name: String, defaultVal: String!) -> String! {
        attributes[name] != nil ? attributes[name] : defaultVal;
    }

    public func getAttribute(_ name: String ) -> String! {
        getAttribute(name, defaultVal: nil)
    }

    // MARK: - Retrieving children elements

    // if <par> tag, a <text> is required (http://www.idpf.org/epub/301/spec/epub-mediaoverlays.html#sec-smil-par-elem)
    public func textElement() -> SmilElement! {
        childWithName("text")
    }

    public func audioElement() -> SmilElement! {
        childWithName("audio")
    }

    public func videoElement() -> SmilElement! {
        childWithName("video")
    }

    public func childWithName(_ name:String) -> SmilElement! {
        for el in children where el.name == name {
            return el
        }
        return nil;
    }

    public func childrenWithNames(_ name:[String]) -> [SmilElement]! {
        var matched = [SmilElement]()
        for el in children {
            if name.contains(el.name) {
                matched.append(el)
            }
        }
        return matched;
    }

    public func childrenWithName(_ name:String) -> [SmilElement]! {
        childrenWithNames([name])
    }

    // MARK: - Audio clip info

    public func clipBegin() -> Double {
        let val = audioElement().getAttribute("clipBegin", defaultVal: "")
        return val!.clockTimeToSeconds()
    }

    public func clipEnd() -> Double {
        let val = audioElement().getAttribute("clipEnd", defaultVal: "")
        return val!.clockTimeToSeconds()
    }
}

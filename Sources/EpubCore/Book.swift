//
//  Book.swift
//  EpubCore
//
//  Created by Heberti Almeida on 09/04/15.
//  Extended by Kevin Jantzer on 12/30/15
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//  Copyright (c) 2015 Kevin Jantzer. All rights reserved.
//  Copyright (c) 2023 Doug Russell. All rights reserved.
//

import Foundation
import ZIPFoundation

final public class Book {
    public var metadata: Metadata = .init()
    public var spine: Spine = .init()
    public var smils: Smils = .init()
    public var version: Double?

    public var opfResource: Resource!
    public var tocResource: Resource?
    public var uniqueIdentifier: String?
    public var coverImage: Resource?
    public var name: String?
    public var resources: Resources = .init()
    public var tableOfContents: [TocReference]!
    public var flatTableOfContents: [TocReference]!
    public var resourceTocMap: [Resource: [TocReference]]!

    public var epubArchive: Archive?

    public var threadEpubArchive: Archive? {
        guard let archiveURL = self.epubArchive?.url,
              let epubArchive = Archive(url: archiveURL, accessMode: .read)
        else { return nil }
        return epubArchive
    }

    public var hasAudio: Bool {
        smils.smils.count > 0
    }

    public var title: String? {
        metadata.titles.first
    }

    public var authorName: String? {
        metadata.creators.first?.name
    }

    public init() {}

    /**
     Find a page by TocReference, i.e IndexPath.row or pageNumber-1
     */
    public func findPageByResource(_ reference: TocReference) -> Int {
        if let resHref = reference.resource?.href,
           let index = resources.findByHref(resHref)?.spineIndices.first {
            return index
        }
            
        return spine.spineReferences.count
    }

    // MARK: - Media Overlay Metadata
    // http://www.idpf.org/epub/301/spec/epub-mediaoverlays.html#sec-package-metadata

    public var duration: String? {
        return metadata.find(byProperty: "media:duration")?.value
    }

    public var activeClass: String {
        guard let className = metadata.find(byProperty: "media:active-class")?.value else {
            return "epub-media-overlay-active"
        }
        return className
    }

    public var playbackActiveClass: String {
        guard let className = metadata.find(byProperty: "media:playback-active-class")?.value else {
            return "epub-media-overlay-playing"
        }
        return className
    }

    // MARK: - Media Overlay (SMIL) retrieval

    /**
     Get Smil File from a resource (if it has a media-overlay)
     */
    public func smilFileForResource(_ resource: Resource?) -> SmilFile? {
        guard let resource = resource, let mediaOverlay = resource.mediaOverlay else { return nil }

        // lookup the smile resource to get info about the file
        guard let smilResource = resources.findById(mediaOverlay) else { return nil }

        // use the resource to get the file
        return smils.findByHref(smilResource.href)
    }

    public func smilFile(forHref href: String) -> SmilFile? {
        smilFileForResource(resources.findByHref(href))
    }

    public func smilFile(forId ID: String) -> SmilFile? {
        smilFileForResource(resources.findById(ID))
    }
    
    // @NOTE: should "#" be automatically prefixed with the ID?
    public func duration(for ID: String) -> String? {
        metadata.find(byProperty: "media:duration", refinedBy: ID)?.value
    }
    
    // MARK: - for Bundle Book
    public var bundleRootTableOfContents: [TocReference]!
    public var bundleBookSizes: [Int]!

    public func updateBundleInfo(rootTocLevel: Int) {
        self.bundleRootTableOfContents = self.flatTableOfContents.filter {
            $0.level == rootTocLevel - 1
        }
        
        self.bundleBookSizes = (bundleRootTableOfContents.startIndex..<bundleRootTableOfContents.endIndex).map { bookTocIndex in
            let bookTocAfterIndex = bundleRootTableOfContents.index(bookTocIndex, offsetBy: 1, limitedBy: bundleRootTableOfContents.endIndex - 1) ?? bookTocIndex
            
            let bookTocSpineIndex = self.findPageByResource(bundleRootTableOfContents[bookTocIndex])
            let bookTocAfterSpineIndex = self.findPageByResource(bundleRootTableOfContents[bookTocAfterIndex])
            
            let bookTocSizeUpto = spine.spineReferences[bookTocSpineIndex].sizeUpTo
            var bookTocAfterSizeUpto = spine.spineReferences[bookTocAfterSpineIndex].sizeUpTo
            
            var bookTocParent = bundleRootTableOfContents[bookTocIndex].parent
            var bookTocAfterParent = bundleRootTableOfContents[bookTocAfterIndex].parent
            while bookTocParent != bookTocAfterParent {
                if let parent = bookTocAfterParent {
                    let parentIndex = self.findPageByResource(parent)
                    bookTocAfterSizeUpto = spine.spineReferences[parentIndex].sizeUpTo
                }
                bookTocParent = bookTocParent?.parent
                bookTocAfterParent = bookTocAfterParent?.parent
            }
            
            return bookTocAfterSpineIndex == bookTocSpineIndex ? spine.size - bookTocSizeUpto : bookTocAfterSizeUpto - bookTocSizeUpto
        }
    }
}

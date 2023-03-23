//
//  StyleOverrideTypes.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 08/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation

public enum StyleOverrideTypes: Int, CaseIterable {
    case None           //0
    case PNode          //1
    case PlusTD         //2
    case PlusSPAN       //3
    case AllText        //4
    
    var description: String {
        get {
            switch(self) {
            case .None:
                return "none"
            case .PNode:
                return "only <p>"
            case .PlusTD:
                return "+ <td>"
            case .PlusSPAN:
                return "+ <span>"
            case .AllText:
                return "all text"
            }
        }
    }
}

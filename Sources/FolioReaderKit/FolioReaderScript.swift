//
//  FolioReaderScript.swift
//  FolioReaderKit
//
//  Created by Stanislav on 12.06.2020.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import WebKit

class FolioReaderScript: WKUserScript {
    
    init(source: String) {
        super.init(source: source,
                   injectionTime: .atDocumentEnd,
                   forMainFrameOnly: true)
    }
    
    @available(iOS 14.0, *)
    override init(source: String,
        injectionTime: WKUserScriptInjectionTime,
        forMainFrameOnly: Bool,
        in contentWorld: WKContentWorld) {
        super.init(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly, in: contentWorld)
    }
    
    static let bridgeJS: FolioReaderScript = {
        let jsURL = Bundle.frameworkBundle().url(forResource: "Bridge", withExtension: "js")!
        let jsSource = try! String(contentsOf: jsURL)
        return FolioReaderScript(source: jsSource)
    }()
    
    static let readiumCFIJS: FolioReaderScript = {
        let jsURL = Bundle.frameworkBundle().url(forResource: "readium-cfi.umd", withExtension: "js")!
        let jsSource = try! String(contentsOf: jsURL)
        return FolioReaderScript(source: jsSource)
    }()
    
    static let cssInjection: FolioReaderScript = {
        let cssURL = Bundle.frameworkBundle().url(forResource: "Style", withExtension: "css")!
        var cssStrings = [String]()
        cssStrings.append(try! String(contentsOf: cssURL))
        
        cssStrings.append(
            contentsOf: FolioReader.FontSizes.map {
                [
                    ".folioStyleFontSize\($0.replacingOccurrences(of: ".", with: "")) p { font-size: \($0) !important; }",
                    ".folioStyleL2FontSize\($0.replacingOccurrences(of: ".", with: "")) td { font-size: \($0) !important; }",
                    ".folioStyleL3FontSize\($0.replacingOccurrences(of: ".", with: "")) span { font-size: \($0) !important; }"
                ]
            }.flatMap{$0}
        )
        
        cssStrings.append(contentsOf: (1...9).map {
            ".folioStyleFontWeight\($0*100) p { font-weight: \($0*100) !important; }"
        })
        
        cssStrings.append(contentsOf: (0...10).map {
            ".folioStyleLetterSpacing\($0) p, .folioStyleLetterSpacing\($0) span { letter-spacing: \(Double($0) / 50.0)em !important; --letter-spacing: \(Double($0) / 50.0)em }"
        })
        
        cssStrings.append(contentsOf: (0...10).map { //1.5 ~ 2.05
            [
                ".folioStyleLineHeight\($0) p, .folioStyleLineHeight\($0) span { line-height: \(Decimal(($0 + 10) * 5) / 100 + 1) !important; }",
                ".folioStyleMargin\($0) p { margin: 1em 0 \((Decimal($0 + 10) * 5) / 100)em 0 !important; }"
            ]
        }.flatMap{$0})
        
        cssStrings.append(contentsOf: (0...8).map {     //-4 ~ 4
            ".folioStyleTextIndent\($0) p { text-indent: calc( (var(--letter-spacing) + 1em) * \(abs($0-4)) ) \($0<4 ? "hanging" : "") !important; text-align: justify !important; -webkit-hyphens: auto !important; }"
        })
        
        cssStrings.append(contentsOf: (0...10).map {
            ".folioStyleBodyPaddingLeft\($0) { padding-left: \(Double($0) * 2.5)vw !important; overflow: hidden !important; }"
        })
        
        cssStrings.append(contentsOf: (0...10).map {
            ".folioStyleBodyPaddingRight\($0) { padding-right: \(Double($0) * 2.5)vw !important; overflow: hidden !important; }"
        })
        
        let cssString = cssStrings.joined(separator: "\n")
        
        return FolioReaderScript(source: cssInjectionSource(for: cssString, id: "folio_bundle_style"))
    }()
    
    static func cssInjection(overflow: String, id: String) -> FolioReaderScript {
        var cssString = "html { overflow: \(overflow) }"
        if overflow == "-webkit-paged-x" {
            cssString =
            """
            html { overflow: -webkit-paged-x; /*margin-top: 20px !important;margin-bottom: 20px !important;*/ }
            body { min-height: 100vh; }
            """
        }
        return FolioReaderScript(source: cssInjectionSource(for: cssString, id: id))
    }
    
    static func cssInjectionSource(for content: String, id: String) -> String {
        let oneLineContent = content.components(separatedBy: .newlines).joined(separator: " ")
        let source = """
        var style = document.createElement('style');
        style.id = '\(id)';
        style.type = 'text/css';
        style.innerHTML = '\(oneLineContent)';
        
        document.head.appendChild(style);
        """
        return source
    }
    
}

extension WKUserScript {
    
    func addIfNeeded(to webView: WKWebView?) {
        guard let controller = webView?.configuration.userContentController else { return }
        let alreadyAdded = controller.userScripts.contains { [unowned self] in
            return $0.source == self.source &&
                $0.injectionTime == self.injectionTime &&
                $0.isForMainFrameOnly == self.isForMainFrameOnly
        }
        if alreadyAdded { return }
        controller.addUserScript(self)
    }
    
}

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
        let cssString = try! String(contentsOf: cssURL)
        return FolioReaderScript(source: cssInjectionSource(for: cssString))
    }()
    
    static func cssInjection(overflow: String) -> FolioReaderScript {
        var cssString = "html { overflow:\(overflow) }"
        if overflow == "-webkit-paged-x" {
            cssString =
            """
            html {
                overflow:-webkit-paged-x;
                /*margin-top: 20px !important;margin-bottom: 20px !important;*/
            }
            body {
                min-height: 100vh;
            }
            @page {
                margin: 5em
            }
            """
        }
        return FolioReaderScript(source: cssInjectionSource(for: cssString))
    }
    
    private static func cssInjectionSource(for content: String) -> String {
        let oneLineContent = content.components(separatedBy: .newlines).joined()
        let source = """
        var style = document.createElement('style');
        style.type = 'text/css'
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

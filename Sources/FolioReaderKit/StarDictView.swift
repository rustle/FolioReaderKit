//
//  StarDictView.swift
//  YetAnotherEBookReader
//
//  Created by 京太郎 on 2021/3/30.
//

import Foundation
import UIKit
import WebKit

open class StarDictViewContainer : UIViewController, WKUIDelegate {
    var webView: WKWebView!
    var word = ""
    
    open override func loadView() {
        super.loadView()
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .null, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
        
        if let url = URL(string: "http://peter-server.lan/stardict.org/ajax_yabr.php") {
            webView.load(URLRequest(url: url))
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //\(word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        webView.evaluateJavaScript("stardict_query(\"\(word)\")", completionHandler: nil)
    }
}

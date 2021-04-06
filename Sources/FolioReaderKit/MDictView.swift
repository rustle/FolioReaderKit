//
//  MDictView.swift
//  YetAnotherEBookReader
//
//  Created by 京太郎 on 2021/3/30.
//

import Foundation
import UIKit
import WebKit

open class MDictViewContainer : UIViewController, WKUIDelegate {
    var webView: WKWebView!
    var server = "http://peter-mdict.lan/"
    var word = ""
    
    open override func loadView() {
        super.loadView()
        
        self.navigationItem.setLeftBarButton(UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(finishReading(sender:))), animated: true)
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .null, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
        
        if let url = URL(string: server) {
            webView.load(URLRequest(url: url))
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let url = URL(string: server + "?word=" + word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) {
            webView.load(URLRequest(url: url))
        }
    }
    
    @objc func finishReading(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}

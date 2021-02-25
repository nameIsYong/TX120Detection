//
//  DetectionWebVC.swift
//  TX120Detection
//
//  Created by mac on 2021/2/4.
//检测页面基类

import Foundation
import UIKit
import WebKit
import JavaScriptCore

class DetectionWebVC: UIViewController,TX120JSExportDelegate{
    var url: String = ""
    
    var webView: WKWebView!
    //private weak
    var jsExport:TX120JSExport?
    private var progressView: UIProgressView!
    private let kNotif_Progress = "estimatedProgress"
    private let kNotif_DismissWeb = "dismissWeb"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TX120Helper.Log("--url-----\(url)")
        if url.count == 0{return}
        UIPasteboard.general.string = url
        
        setupSubViews()
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: TimeInterval(0))) {
        }
    }
    
    deinit {
        jsExport?.removeMethods(content: webView.configuration.userContentController,methodList: getRegisteMethods())
        webView?.removeObserver(self, forKeyPath: kNotif_Progress)
        NotificationCenter.default.removeObserver(self)
        TX120Helper.Log("父类VC====销毁")
    }
   
    //获取注册方法(子类增加并实现自己的方法)
    func getRegisteMethods()->[(target:NSObject,method:Selector)]{
        //.... 子类实现自己的方法
        return [(self,#selector(goBack))]
    }
    
    private func setupSubViews(){
        
        let config = WKWebViewConfiguration()
        let jsExport = TX120JSExport()
        jsExport.delegate = self
        let content  = WKUserContentController()
        jsExport.addMethods(content: content,methodList: getRegisteMethods())
        self.jsExport = jsExport
        config.userContentController = content
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.addObserver(self, forKeyPath:kNotif_Progress, options: .new, context: nil)
        
        var stateBarH = UIApplication.shared.statusBarFrame.size.height
        if #available(iOS 11.0, *) {
            stateBarH += self.view.safeAreaInsets.bottom
       }

        webView.frame = CGRect(x: 0, y: stateBarH, width: self.view.frame.size.width, height: self.view.frame.size.height-stateBarH-300)
        self.webView = webView
        self.view.addSubview(webView)

        progressView = UIProgressView(progressViewStyle: .default)
        progressView.frame = CGRect(x: 0, y: 0, width:self.view.frame.size.width, height: 1)
        progressView.trackTintColor = .white
        progressView.progressTintColor = UIColor.systemGreen
        progressView.transform = CGAffineTransform(scaleX: 1, y: 1.5)
        webView.addSubview(progressView)

        if url.hasPrefix("http"){
            var urlStr = URL(string: url)
            if urlStr == nil {
                let tempUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                urlStr = URL(string: tempUrl)
            }
            
            guard let requestUrl = urlStr else {return}
            let request = URLRequest(url: requestUrl)
            self.webView.load(request)

        }else if url.hasSuffix(".html"){//加载本地html
            
            let urlStr = URL(fileURLWithPath: url)
            let requestUrl = URLRequest(url: urlStr)
            TX120Helper.Log("\(requestUrl)")
            webView.load(requestUrl)

        }else if url.hasPrefix("<html"){//加载html代码
            self.webView.loadHTMLString(url, baseURL: nil)
            
        }else if url.count > 0{//加载文本
            let htmlString = "<html><head><meta name=\"viewport\" content=\"width=device-width,minimum-scale=1.0,maximum-scale=1.0,user-scalable=no\"/><style type=\"text/css\">img {max-width:100%%;height:auto;}</style></head><body>\(url)</body></html>"
            self.webView.loadHTMLString(htmlString, baseURL: nil)
        }
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == kNotif_Progress {
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
            if self.progressView.progress == 1 {
                UIView.animate(withDuration: 0.25, delay: 0.3, options: .curveEaseInOut, animations: {[weak self] in
                    self?.progressView.transform = CGAffineTransform(scaleX: 1.0, y: 1.4)
                }) {[weak self] (finished) in
                    self?.progressView.isHidden = true
                    self?.progressView.setProgress(0, animated: false)
                }
            }
        }
    }
    
    
}

extension DetectionWebVC{
    //返回
    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }else{
            backVC()
        }
    }
    
    ///返回上层VC
    func backVC(){
        if self.navigationController != nil {
            //prent过来的
            let fristVC = self.navigationController?.childViewControllers.first
            if fristVC != nil && fristVC == self{
                self.dismiss(animated: true, completion: nil)
            }else{
                self.navigationController?.popViewController(animated: true)
            }
        }else {
            //prent过来的
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension DetectionWebVC: WKUIDelegate, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.progressView.isHidden = false
        self.progressView.transform = CGAffineTransform(scaleX: 1, y: 1.5)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.progressView.isHidden = true
        TX120Helper.Log("--->"+error.localizedDescription)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        TX120Helper.Log("--->"+error.localizedDescription)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(WKNavigationActionPolicy.allow)
    }

}

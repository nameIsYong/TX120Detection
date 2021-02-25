//
//  TX120JSExport.swift
//  TX120Detection
//
//  Created by mac on 2021/2/4.
//

import Foundation
import UIKit
import JavaScriptCore
import WebKit

public protocol TX120JSExportDelegate: NSObjectProtocol {
    ///获取js调用原生的方法列表
    func getRegisteMethods()->[(target:NSObject,method:Selector)];
}


public class TX120JSExport: NSObject,JSExport,WKScriptMessageHandler {
   
    weak var delegate:TX120JSExportDelegate?
    
    private func change(methods:[(target:NSObject,method:Selector)]) -> [(target:NSObject,method:String)] {
        
        var methodList:[(target:NSObject,method:String)] = []
        for obj in methods{
            var method = NSStringFromSelector(obj.method)
            //注意sel不能有超过1个参数
            if method.hasSuffix(":"){
                method = method.replacingOccurrences(of: ":", with: "")
            }
            methodList.append((obj.target,method))
        }
        
        return methodList
    }
   
    deinit {
       TX120Helper.Log("TX120JSExport---销毁")
    }
}


extension TX120JSExport
{
    
    func addMethods(content:WKUserContentController,methodList:[(target:NSObject,method:Selector)]){
        
        let dataSour = change(methods: methodList)
        for obj in dataSour{
            content.removeScriptMessageHandler(forName: obj.method)
            content.add(self, name: obj.method)
        }
    }
    
    func removeMethods(content:WKUserContentController,methodList:[(target:NSObject,method:Selector)]) {
        let dataSour = change(methods: methodList)
        for item in dataSour{
            content.removeScriptMessageHandler(forName: item.method)
        }
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        DispatchQueue.main.async(execute: {
           
            let method = message.name
            let body = message.body as? String ?? ""
            TX120Helper.Log("--js调用OC方法：\(method),参数：\(body)")
            let dataSource = self.delegate?.getRegisteMethods() ?? []
            let memthodList = self.change(methods: dataSource)
            //其他扩展业务（新扩展业务都按此方法添加）
            for mtObj in memthodList{
                if method == mtObj.method{
                    let sel = Selector.init(method)
                    if mtObj.target.responds(to:sel){
                        mtObj.target.perform(sel, with: body)
                        return
                    }
                }
            }
        })
       
    }
    
}

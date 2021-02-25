//
//  BloodDetectionWebVC.swift
//  TX120Detection
//
//  Created by mac on 2021/2/4.
//血糖、尿酸、总胆固醇、血酮检测页面

import Foundation
import UIKit
import JavaScriptCore

class BloodDetectionWebVC: DetectionWebVC{
    
    private var manager:BloodMananger?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red
    }
    
    override func getRegisteMethods() -> [(target: NSObject, method: Selector)] {
        var methods = super.getRegisteMethods()
        methods.append((self,#selector(startDetection)))
        methods.append((self,#selector(endDetection)))
        return methods
    }
    
    ///结束检测
    @objc private func endDetection(){
        manager?.stopDetection()
        self.backVC()
    }
    
    ///开始监测
    @objc private func startDetection(){
        if manager == nil{
            manager = BloodMananger()
            manager?.valueDelegate = self
        }
        manager?.startBy(type: .t_Ketone, deviceNames:["j-tianxia120","Laya","MKTECH"], timeout: 10)
    }
    
    deinit {
        manager?.stopDetection()
    }
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        ///原生调用js
//        self.webView?.evaluateJavaScript("sayHello('nihao')", completionHandler: { (data
//                    , error) in
//            print(data as Any)
//        })
//    }
}

extension BloodDetectionWebVC:BloodDataDelegate{
    
    func onGetDeviceId(manager: BloodMananger, deviceSin: String) {
        
    }
    
    func paperOnInsert(manager: BloodMananger, error: String?) {
        let str = error == nil ? "试纸插入成功" : error!
        TX120Helper.Log("插入试纸:\(str)")
    }
    
    func paperOnChange(manager: BloodMananger, status: PaperStatus, info: String?) {
        TX120Helper.Log("插入操作:\(info ?? "")")
    }
    
    func onGetDetectionTime(manager: BloodMananger, time: Int) {
        TX120Helper.Log("检测时间:\(time)")
    }
    
    func onDidDetection(manager: BloodMananger, value: CGFloat) {
        TX120Helper.Log("检测Over:\(value)")
    }
    
    
}



















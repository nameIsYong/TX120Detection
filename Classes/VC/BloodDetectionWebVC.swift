//
//  BloodDetectionWebVC.swift
//  TX120Detection
//
//  Created by mac on 2021/2/4.
//血糖、尿酸、总胆固醇、血酮检测页面

import Foundation
import UIKit
import JavaScriptCore

public class BloodDetectionWebVC: DetectionWebVC{
    
    private var manager:BloodMananger?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red
    }
    
    public override func getRegisteMethods() -> [(target: NSObject, method: Selector)] {
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
            manager?.deviceDelegate = self
        }
        manager?.startBy(type: .t_Ketone, deviceNames:["j-tianxia120","Laya","MKTECH"], timeout: 10)
    }
    
    deinit {
        manager?.stopDetection()
    }
}

extension BloodDetectionWebVC:BloodDeviceDelegate{
    func paperInsertOn(error: String, manager: BloodMananger) {
        TX120Helper.Log("插入试纸:\(error)")
    }
    
    func onGetDeviceId(manager: BloodMananger, deviceSin: String) {
        
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



















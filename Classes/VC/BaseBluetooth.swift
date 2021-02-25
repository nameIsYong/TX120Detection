//
//  BaseBluetooth.swift
//  TX120Detection
//
//  Created by mac on 2021/2/2.
//

import Foundation
import CoreBluetooth

///连接状态
protocol BluetoothStatusDelegate: class {
    func connectFail(manager:BaseBluetooth,status:CBManagerState?,error:String?)
    func didConnected(manager:BaseBluetooth)
    func didDisconnect(manager:BaseBluetooth)
}

class BaseBluetooth: NSObject {
    public weak var statusDelegate:BluetoothStatusDelegate?
    //蓝牙检测
    public var manager:CBCentralManager!
    ///当前设备
    public var curPheral:CBPeripheral?
    ///扫描的设备名称
    public var deviceNames:[String] = []
    ///超时时间
    private var timeout = 15
    //超时监听器
    private weak var timer:Timer?
    
    ///停止扫描
    public func stopDetection() {
        removeTimer()
        if manager?.isScanning ?? false{manager?.stopScan()}
        if let pheral = curPheral{
            manager.cancelPeripheralConnection(pheral)
         }
        manager?.delegate = nil
        manager = nil
        curPheral = nil
    }
    
    ///监听超时
    public func listenTimeout(_ timeOutCount:Int) {
        timer?.invalidate()
        timeout = timeOutCount
        self.timer  = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkDidCounted), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: RunLoopMode.commonModes)
    }
    
    deinit {
        removeTimer()
    }
}


extension BaseBluetooth: CBCentralManagerDelegate {
    ///蓝牙链接状态
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var message:String?
        switch central.state {
        case .unknown:
            message = "蓝牙系统错误"
        case .resetting:
            message = "请重新开启手机蓝牙"
        case .unsupported:
            message = "该手机不支持蓝牙"
        case .unauthorized:
            message = "蓝牙权限已关闭，请打开权限"
        case .poweredOff:
            message = "手机蓝牙未开启，请开启蓝牙"
        case .poweredOn:
            if deviceNames.isEmpty || statusDelegate == nil{
                TX120Helper.Log("请实现BluetoothStatusDelegate")
                removeTimer()
                return}
            central.scanForPeripherals(withServices: nil, options: nil)
        @unknown default:
            message = "连接错误"
        }
        if let error = message,error.count > 0{
            removeTimer()
            statusDelegate?.connectFail(manager: self, status: central.state, error: message)
        }
    }
    
    ///正在扫描
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let findName = peripheral.name ?? ""
        TX120Helper.Log("设备名-->"+(findName))
        for name in deviceNames{
            if name.contains(findName){
                curPheral = peripheral
                central.connect(peripheral, options: nil)
                break
            }
        }
    }
    
    ///已连接
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        central.stopScan()
        removeTimer()
        statusDelegate?.didConnected(manager: self)
    }
    
    ///连接失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        removeTimer()
        statusDelegate?.connectFail(manager: self, status: nil, error: error?.localizedDescription)
        
    }
    
    ///断开连接
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        statusDelegate?.didDisconnect(manager: self)
    }
    
}


extension BaseBluetooth{
    
    ///删除监听器
    private func removeTimer() {
        TX120Helper.Log("------定时器销毁---")
        timer?.invalidate()
        timer = nil
    }
    
    ///检测蓝牙是否连接成功
   @objc private func checkDidCounted() {
    
        if (timeout <= 0) {
            stopDetection()
            statusDelegate?.connectFail(manager: self, status: nil, error: "连接超时，请确认检测设备和手机已开启蓝牙")
        }else{
            timeout = timeout - 1
            TX120Helper.Log("-------倒计时-->\(self.timeout)")
        }
    }
}

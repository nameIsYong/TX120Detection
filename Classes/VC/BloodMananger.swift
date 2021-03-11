//
//  BloodMananger.swift
//  TX120Detection
//
//  Created by mac on 2021/2/2.
//血糖，尿酸，总胆固醇,血酮

import Foundation
import CoreBluetooth
import UIKit

///连接状态
protocol BloodBluethStatusDelegate: BluetoothConnectDelegate {
    
}

///数据读写
protocol BluetoothWriteReadDelegate: class {
    ///找到了写服务
    func deviceFind(manager:BloodMananger,write:CBCharacteristic)
    ///找到了读服务
    func deviceFind(manager:BloodMananger,read:CBCharacteristic)
    ///接收到数据(可实现BloodDataDelegate代理来管理业务)
    func deviceDidReceive(manager:BloodMananger,data:Data)
}


///检测设备代理（也可自己实现deviceDidReceive来解析数据）
protocol BloodDeviceDelegate: class {
    
    ///插入错误试纸则会报错回调
    func paperInsertOn(error:String,manager:BloodMananger)
    ///试纸状态改变（试纸已插入，试纸已拔出...）
    func paperOnChange(manager:BloodMananger,status:PaperStatus,info:String?)
    ///获取到检测时间
    func onGetDetectionTime(manager:BloodMananger,time:Int)
    //获取到硬件唯一ID
    func onGetDeviceId(manager:BloodMananger,deviceSin:String)
    ///检测完成
    func onDidDetection(manager:BloodMananger,value:CGFloat)
}

///三合一检测类型
enum PaperStatus: String {
    ///插入试纸
    case k_didPaperIn = "TextPaperIN"
    ///滴入血液
    case t_didDropLiquid = "DropLiquid"
    ///试纸拔出
    case t_didTextPaperOut = "TextPaperOut"
    ///检测中
    case t_Checking = "exting Please wait"
    ///试纸过期
    case t_Error_Init = "ERR1"
    ///试纸过期
    case t_Error_PaperExceed = "ERR2"
    ///滴入血量有误
    case t_Error_Operation = "ERR3"
    ///试纸类型错误
    case t_Error_PaperType = "TextPaperError"
    ///系统错误
    case t_Error_Sys = "ERR4"
    ///测量完成
    case t_TextOver = "TextOver"
}

///三合一检测类型
enum DetectionType: String {
    ///血糖
    case t_Sugar = "Blood_Sugar"
    ///尿酸
    case t_Uric = "Uric_Acid"
    ///胆固醇
    case t_Chol = "Cholesterol"
    ///血酮
    case t_Ketone = "Blood_Ketone"
    ///甘油三酯
    case t_TG = "t_TG"
    ///高密度
    case t_HDL = "t_HDL"
}

class BloodMananger: BaseBluetooth {
    ///蓝牙链接状态
    public weak var statusDelegate:BloodBluethStatusDelegate?
    ///读写服务代理
    public weak var writeReadDelegate:BluetoothWriteReadDelegate?
    ///数据回调代理
    public weak var deviceDelegate:BloodDeviceDelegate?
    
    //写入特征
    private var writeCharacteristic: CBCharacteristic?
    //读取特征
    private var readCharacteristic: CBCharacteristic?
    //检测类型
    private var detectionType:DetectionType!
    private let kDeviceServiceUUID = "FFE0"
    private let kDeviceReadUUID = "FFE4"
    private let kDeviceWriteUUID = "FFE8"
    private var lastOperation = ""
    
    ///三代产品兼容
    public func getDeviceNameList()->[String]{
        return ["j-tianxia120","Laya","MKTECH"]
    }
    
    ///默认的检测等待时间
    public func getDefaultTimeBy(_ detectionType:DetectionType)->Int{
        switch detectionType{
        case .t_Sugar:
            return 6
        case .t_Uric:
            return 20
        case .t_Chol:
            return 60
        case .t_Ketone:
            return 6
        default:return 0
        }
    }
   
    
    deinit {
        TX120Helper.Log("BloodMananger----deinit")
    }
}

extension BloodMananger{
    
    /**
     开始扫描
     type：检测类型，deviceNames：设备蓝牙名称，timeout：超时时间
     */
    public func startBy(type:DetectionType,deviceNames:[String],timeout:Int = 20){
        if deviceNames.isEmpty{return}
        stopDetection()
        manager = CBCentralManager(delegate: nil, queue: nil)
        manager.delegate = self
        self.connectDelegate = self//default
        self.detectionType = type
        self.deviceNames = deviceNames
        self.lastOperation = ""
        listenTimeout(timeout)
        manager.scanForPeripherals(withServices: nil, options: nil)
    }
    
}

extension BloodMananger:BluetoothConnectDelegate{
    ///蓝牙链接失败
    internal func connectFail(manager: BaseBluetooth, status: CBManagerState?, error: String?) {
        statusDelegate?.connectFail(manager: self, status: status, error: error)
        if let msg = error,msg.count > 0{
            if status == .poweredOff{
                UIAlertController.alert_(vc: nil, msg:"蓝牙未开启，是否去开启") {
                    TX120Helper.openSeting()
                }
            }else{
                UIAlertController.alert_(msg)
            }
        }
    }
    
    ///蓝牙链接成功
    internal func didConnected(manager: BaseBluetooth) {
        manager.curPheral?.delegate = self
        let uuids = [CBUUID(string:kDeviceServiceUUID)]
        manager.curPheral?.discoverServices(uuids)
        statusDelegate?.didConnected(manager: manager)
    }
    
    ///蓝牙断开
    internal func didDisconnect(manager: BaseBluetooth) {
        UIAlertController.alert_("蓝牙已断开")
        statusDelegate?.didDisconnect(manager: manager)
    }
    
}


extension BloodMananger: CBPeripheralDelegate {
    //发现服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            if service.uuid.uuidString == kDeviceServiceUUID {
                peripheral.discoverCharacteristics(nil, for: service)
                break
            }
        }
    }
    
    //发现特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for serItem in service.characteristics ?? [] {
            if serItem.uuid.uuidString == kDeviceReadUUID{
                readCharacteristic = serItem
                writeReadDelegate?.deviceFind(manager: self, read: serItem)
                peripheral.setNotifyValue(true, for: serItem)
                
            }
            
            let value = serItem.properties.rawValue
            let canWrite = (value&0x04) == 4 || (value&0x08) == 8
            if canWrite && serItem.uuid.uuidString == kDeviceWriteUUID{
                writeCharacteristic = serItem
                writeReadDelegate?.deviceFind(manager: self, write: serItem)
                //同步时间到手柄
                let timeData = getCr8TimeData()
                peripheral.writeValue(timeData, for:serItem, type: .withoutResponse)
                
            }
        }
    }
    
    //订阅状态
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard error==nil else {
         return
        }
    }
    
    //接收到数据
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard let data = characteristic.value else {return}
        let dataArry:[UInt8] = [UInt8](data)
        if dataArry.count == 9 && dataArry[0] == 2{return}
        guard let receiveStr = String.init(data: data, encoding: String.Encoding.utf8) else {return}
        TX120Helper.Log("接收到数据：\(receiveStr)")
        
        
        writeReadDelegate?.deviceDidReceive(manager:self, data:data)
        //若用户实现了该代理，则自动为其解析对应数据类型，否则通过上面代理，让用户自己解析
        if let valueDel = deviceDelegate{
            
            //插入试纸监听
            let obj = BloodMananger.getPaperType(receiveStr, detectionType: detectionType)
            if obj.isInserPaper,let error = obj.error{
                valueDel.paperInsertOn(error: error, manager: self)
            }
            
            //获取监测等待时间
            let waitTime = self.getWaitTime(receiveStr, detectionType)
            if waitTime > 0{
                valueDel.onGetDetectionTime(manager: self, time: waitTime)
            }
            
            //获取设备硬件ID
            if let deviceSin = self.getDeviceSin(receiveStr){
                valueDel.onGetDeviceId(manager: self, deviceSin: deviceSin)
            }
            
            //试纸状态监听
            let staObj = BloodMananger.getPaperStatus(ext: receiveStr)
            if let status = staObj.type{
                valueDel.paperOnChange(manager: self, status:status, info: staObj.info)
            }
            
            //获取监测结果
            let value = getDetectionResult(receiveStr)
            if value > 0{
                valueDel.onDidDetection(manager: self, value: value)
            }
            
            //记录上一次发送的数据，因为可能TextOver和结果分开发送过来
            lastOperation = receiveStr
        }
    }
    
}


extension BloodMananger{
    
    /**
     获取等待时间
     返回格式：Uric_Acid\r\n21
     */
    func getWaitTime(_ reciveStr:String,_ type:DetectionType)->Int{
        var str = reciveStr.replacingOccurrences(of: "\r\n", with: "")
        str = str.replacingOccurrences(of: " ", with: "")
        let array = str.regexGetSub_(pattern: "\(type.rawValue)\\d+")
        if let last = array.last{
            let numStr = last.regexGetSub_(pattern: "\\d+").last ?? ""
            let num = numStr.intValue_()
            if num > 0{return num}
        }
        return 0
    }
    
    
    ///获取设备硬件ID,判断是否包含设备ID，这里拼接上一次发送的数据，
    ///因为蓝牙发送数据太长后，可能会分成两次发送，16进制设备ID
    func getDeviceSin(_ reciveStr:String)->String?{
        let str = reciveStr.replacingOccurrences(of: "\r\n", with: "")
        let oldStr = lastOperation.replacingOccurrences(of: "\r\n", with: "")
        let tempStr = oldStr + str
        let reg = "[A-Fa-f0-9]{12}"
        if tempStr.contains("Device_Id:"){
            if let content = tempStr.regexGetSub_(pattern: "Device_Id:\(reg)").first{
                if let deviceId = content.regexGetSub_(pattern: reg).first{
                    TX120Helper.Log("设备ID:\(deviceId)")
                    return deviceId
                }
            }
        }
        
        return nil
    }
    
    
    
    ///更新手柄时间，同步时间
    private func getCr8TimeData()->Data{
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyMMddHHmmss"
        let time = dformatter.string(from: Date())
        var crc8Data = ""
        crc8Data.append("A1")
        crc8Data.append("06")
        crc8Data.append(time)
        let byte = crc8Data.hexStrTobytes()
        let crc8Hex  = String.crc8(bytes: byte)
        var data:String = "02FD"//帧头
        data.append("A1")//CMD固定
        data.append("06")//长度固定
        data.append(time)//数据
        data.append(crc8Hex.uppercased())//校验
        data.append("FD02")//帧尾
        let bytes = String.bytes(from: data)
        return Data.init(bytes: bytes, count: bytes.count)
    }
    
    ///获取结果
    private func getDetectionResult(_ receiveStr:String)->CGFloat{
        let strArr = receiveStr.components(separatedBy: "\r\n")
        var valueFloat:CGFloat = 0
        
        let overStr = PaperStatus.t_TextOver.rawValue
        
        if receiveStr.contains(overStr) || lastOperation.contains(overStr){
            for value in strArr{
                if value.isNum_() || value.isDoubNum_(){
                    if let v = value.toFloat_(){
                        valueFloat = CGFloat(v)
                        break
                    }
                }
            }
        }
        if valueFloat > 0 {
            //第一代老设备
            if deviceNames.contains("Laya"){
                switch detectionType{
                case .t_Sugar:
                    valueFloat = valueFloat / 18.0
                case .t_Uric:
                    valueFloat = valueFloat / 0.01681 / 10.0
                case .t_Chol:
                    valueFloat = valueFloat / 38.67
                case .t_Ketone:
                    valueFloat = valueFloat / 10.4
                default:
                    break
                }
                
            }else{ //新设备MKTECH
                switch detectionType{
                case .t_Sugar:
                    valueFloat = valueFloat / 100
                case .t_Uric:
                    valueFloat = valueFloat / 10
                case .t_Chol:
                    valueFloat = valueFloat / 100
                case .t_Ketone:
                    valueFloat = valueFloat/100 //10.4
                default:
                    break
                }
            }
        }
        return CGFloat(valueFloat)
    }
    
    ///是否插入的正确试纸
    class func getPaperType(_ content:String,detectionType:DetectionType)->(isInserPaper:Bool,error:String?){
        
        let sugar = content.contains(DetectionType.t_Sugar.rawValue)
        let chol = content.contains(DetectionType.t_Chol.rawValue)
        let uric = content.contains(DetectionType.t_Uric.rawValue)
        let ketone = content.contains(DetectionType.t_Ketone.rawValue)
        
        if sugar || chol || uric || ketone{
            let isTrue = content.contains(detectionType.rawValue)
            return isTrue ? (true,nil) : (true,"插入的试纸错误，请更换试纸，重新插入")
        }
        return (false,nil)
    }
    
    //获取蓝牙状态
    class func getPaperStatus(ext:String)->(type:PaperStatus?,info:String?){
        if (ext.contains(PaperStatus.k_didPaperIn.rawValue)){
            return (.k_didPaperIn,"试纸插入成功，请滴入血液")
        }
        if (ext.contains(PaperStatus.t_didDropLiquid.rawValue)) {
            return (.t_didDropLiquid,"血液滴入成功，请等待结果")
        }
        if (ext.contains(PaperStatus.t_didTextPaperOut.rawValue)) {
            return (.t_didTextPaperOut,"试纸拔出")
        }
        if (ext.contains(PaperStatus.t_Error_Init.rawValue)) {
            return (.t_Error_Init,"开机自检异常")
        }
        if (ext.contains(PaperStatus.t_Error_PaperExceed.rawValue)) {
            return (.t_Error_PaperExceed,"试纸过期")
        }
        
        if (ext.contains(PaperStatus.t_Error_Operation.rawValue)) {
            return (.t_Error_Operation,"滴血测量操作有误")
        }
        if (ext.contains(PaperStatus.t_Error_Sys.rawValue)) {
            return (.t_Error_Sys,"系统错误")
        }
        if (ext.contains(PaperStatus.t_Checking.rawValue)) {
            return (.t_Checking,"测试中请等待")
        }
        if (ext.contains(PaperStatus.t_TextOver.rawValue)) {
            return (.t_TextOver,"测量完成")
        }
        return (nil,nil)
    }
}


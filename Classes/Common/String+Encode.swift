//
//  String+Encode.swift
//  TX120Detection
//
//  Created by mac on 2021/2/3.
//

import Foundation

public extension String{
    ///16进制转转整形数组
    static func bytes(from hexStr: String) -> [UInt8] {
        assert(hexStr.count % 2 == 0, "输入字符串格式不对，8位代表一个字符")
        var bytes = [UInt8]()
        var sum = 0
        // 整形的 utf8 编码范围
        let intRange = 48...57
        // 小写 a~f 的 utf8 的编码范围
        let lowercaseRange = 97...102
        // 大写 A~F 的 utf8 的编码范围
        let uppercasedRange = 65...70
        for (index, c) in hexStr.utf8CString.enumerated() {
            var intC = Int(c.byteSwapped)
            if intC == 0 {
                break
            } else if intRange.contains(intC) {
                intC -= 48
            } else if lowercaseRange.contains(intC) {
                intC -= 87
            } else if uppercasedRange.contains(intC) {
                intC -= 55
            } else {
                assertionFailure("输入字符串格式不对，每个字符都需要在0~9，a~f，A~F内")
            }
            sum = sum * 16 + intC
            // 每两个十六进制字母代表8位，即一个字节
            if index % 2 != 0 {
                bytes.append(UInt8(sum))
                sum = 0
            }
        }
        return bytes
    }
    
    static func crc8(bytes:[Int])->String{

        var crc = 0x00
        for item in bytes{
            crc ^= Int(item)
            for _ in 0..<8{
                if((crc & 0x01) != 0){
                    crc = (crc >> 1) ^ 0x8C;
                }else{
                    crc >>= 1
                }
            }
        }
        let crc8Str:String = String(format: "%.2x", crc)
        return crc8Str
    }

    ///正则，找出指定字符串
    func regexGetSub_(pattern:String) -> [String] {
        var subStr:[String] = []
         let regex = try? NSRegularExpression(pattern: pattern, options:[])
            if let regexPar = regex{
                let matches = regexPar.matches(in: self, options: [], range: NSRange(self.startIndex...,in: self))
                for  match in matches {
                   let matchStr = (self as NSString).substring(with: match.range)
                    subStr.append(matchStr)
                }
            }
         
         return subStr
    }
    ///是否是正整纯数字
    func isNum_()->Bool{
        let regex = "\\d+"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with:self)
    }
    
    ///是否是数字(包含小数)
    func isDoubNum_()->Bool{
        let regex = "^[1-9]\\d*\\.\\d*|0\\.\\d*[1-9]\\d*$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        let v = predicate.evaluate(with:self)
        return v
    }
    
    ///转CGFloat
    func toFloat_() -> Float?{
        if let num = NumberFormatter().number(from: self) {
            return num.floatValue
        } else {
            return nil
        }
    }
    
    ///自定义转整数
    func intValue_()->Int{
        if self == ""{return -1}
        if let num = NumberFormatter().number(from: self) {
            return num.intValue
        } else {
            return -1
        }
    }
}

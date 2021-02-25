//
//  String+Encode.swift
//  TX120Detection
//
//  Created by mac on 2021/2/3.
//

import Foundation

public extension String{
    ///16进制字符串转byte
    func hexStrTobytes()->[Int]{
        let hexStr = self
        var bytes:[Int] = []
        // 整形0~9的 utf8 编码范围
        let intRange = 48...57
        // 小写 a~f 的 utf8 的编码范围
        let lowercaseRange = 97...102
        // 大写 A~F 的 utf8 的编码范围
        let uppercasedRange = 65...70
        
        var index = 0
        let charArray = hexStr.utf8CString
        
        while index < charArray.count{
            //两位16进制数中的第1位(高位*16)
            let c = charArray[index]
            let intC = Int(c.byteSwapped)
            
            var num1 = 0
            if intRange.contains(intC){
                num1 = (intC - 48) * 16 //0 的Ascll - 48
                
            }else if uppercasedRange.contains(intC){
                num1 = (intC - 55) * 16 //A 的Ascll - 65
                
            }else if lowercaseRange.contains(intC){
                num1 = (intC - 87) * 16 // a 的Ascll - 97
            }
            
            let last = index + 1
            //两位16进制数中的第二位(低位)
            var num2 = 0
            if last < charArray.count{
                let int2C = Int(charArray[last].byteSwapped)
                
                if intRange.contains(int2C){
                    num2 = (int2C - 48)
                }else if uppercasedRange.contains(int2C){
                    num2 = (int2C - 55)
                }else if lowercaseRange.contains(int2C){
                    num2 = (int2C - 87)
                }
                bytes.append(num1+num2)
            }
            index += 2
        }
        return bytes
    }
    
    ///获取crc8校验符号
    static func crc8String(bytes:[Int])->String{
        var crc = 0x00
        for item in bytes{
            crc ^= item
            for _ in 0..<8{
                if((crc & 0x01) != 0){
                    crc = (crc >> 1) ^ 0x8C;
                }else{
                    crc >>= 1
                }
            }
        }
        let crc8Str = String(format: "%.2x", crc)
        return crc8Str
    }
}
extension Data{
    func toHexString()->String{
        let str = self.map { String(format: "%02X", $0) }.joined(separator: "")
        return str
    }
}

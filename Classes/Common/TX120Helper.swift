//
//  TX120Helper.swift
//  TX120Detection
//
//  Created by mac on 2021/2/2.
//

import Foundation
import UIKit

public class TX120Helper: NSObject {
    
    ///开始设置页面
    public class func openSeting(){
        if let url = URL(string:UIApplicationOpenSettingsURLString){
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: {
                    (bool)in
                })
            }
        }
    }
    
    ///打印
    public class func Log(_ info:String){
        print("---\(info)")
    }
}

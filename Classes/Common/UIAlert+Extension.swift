//
//  UIAlert+Extension.swift
//  TX120Detection
//
//  Created by mac on 2021/2/2.
//

import Foundation
import UIKit

public extension UIAlertController {
    func show() {
        UIApplication.shared.keyWindow?.rootViewController?.present(self, animated: true, completion: nil)
    }
  
    ///一个取消，确定 的默认提示消息
    class func alert_(vc:UIViewController?,msg:String,block:@escaping (()->())) {
        let alertVC = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        let ok = UIAlertAction(title: "确定", style: .default) { (action) in
            
            block()
        }
        let cancel = UIAlertAction(title: "取消", style: .cancel) { (action) in
        }
        alertVC.addAction(cancel)
        alertVC.addAction(ok)
        if vc == nil{
            alertVC.show()
        }else{
            vc?.present(vc!, animated: true, completion: nil)
        }
    }
    
    ///显示一个“知道了”提示
    class func alert_(_ msg:String?) {
        if let str = msg{
            if str.count == 0{return}
           alert_("提示", str)
        }
    }
    ///显示一个“知道了”提示
    class func alert_(_ title:String?,_ msg:String) {
        if msg.count == 0{return}
        let alertVC = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let ok = UIAlertAction(title:"知道了", style: .default) { (action) in}
        alertVC.addAction(ok)
        alertVC.show()
    }
   
}

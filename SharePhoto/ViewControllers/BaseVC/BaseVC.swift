//
//  BaseVC.swift
//  SharePhoto
//
//  Created by Admin on 2/15/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit
import MBProgressHUD

class BaseVC: UIViewController {

    private var hud: MBProgressHUD = MBProgressHUD()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.hud)
    }
    
    func showBusyDialog() {
        self.hud.label.text = ""
        self.hud.show(animated: true)
    }
    
    func showBusyDialog(_ title: String) {
        self.hud.label.text = title
        self.hud.show(animated: true)
    }
    
    func hideBusyDialog() {
        self.hud.hide(animated: true)
    }

}

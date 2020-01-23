//
//  HCModule.swift
//  HelpCrunchModule
//
//  Created by Admin on 1/23/2020.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import HelpCrunchSDK

class HCModule: NSObject {
    static func updateHelpCrunchUserInfo() {
        if Global.helpCrunchInited == false || Global.username == nil {
            return
        }

        let user = HCSUser()
        user.userId = Global.userid!
        user.name = Global.username!
        user.email = Global.email!
        
        //HelpCrunch.bindTheme(HelpCrunch.darkTheme())
        HCModule.setCustomTheme()
        
        debugPrint("---HelpCrunch update user start!")
        HelpCrunch.update(user) { (error) in
            if error == nil {
                debugPrint("---HelpCrunch update user success!")
            } else {
                debugPrint("---HelpCrunch update user fail! \(error!)")
            }
        }
    }
    
    static func setCustomTheme() {
        let theme = HelpCrunch.darkTheme()
        
        //theme.mainColor = UIColor(red: 0.90, green: 0.51, blue: 0.15, alpha: 1.0)
        theme.navigationBarBackgroundColor = UIColor(red: 0.1, green: 0.12, blue: 0.12, alpha: 1.0)

        HelpCrunch.bindTheme(theme)
    }
}

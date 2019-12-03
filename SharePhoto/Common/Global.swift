//
//  Global.swift
//  Google User
//
//  Created by Admin on 11/6/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

class Global: NSObject {
    static var user: GIDGoogleUser?
    static var email: String?
    
    static var needRefreshLocal = true
    static var needRefreshStorage = true
    
    static func setNeedRefresh() {
        needRefreshLocal = true
        needRefreshStorage = true
    }
}

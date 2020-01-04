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
    static let sharedFolderName = "Ohana Sync"
    
    static var user: GIDGoogleUser?
    static var email: String?

    static var needRefreshLocal = true
    static var needRefreshStorage = true
    static var needDoneSelectionAtHome = false    // exit from photo selection at Home Tab (download complete)

    static var selectedCloudPhotos: [FSPhotoInfo]?
    
    static func setNeedRefresh() {
        needRefreshLocal = true
        needRefreshStorage = true
    }
    
    static func doneDownload() {
        self.needDoneSelectionAtHome = true
    }
    
    static func getProcessResultMsg(titles: [String], counts:[Int]) -> String {
        var strMsg: String = ""

        for i in 0 ..< titles.count {
            if counts[i] <= 0 {
                continue
            }
            
            if strMsg == "" {
                strMsg = titles[i] + ": " + "\(counts[i])"
            } else {
                strMsg += ",\n" + titles[i] + ": " + "\(counts[i])"
            }
        }

        return strMsg
    }
}

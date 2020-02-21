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

class SearchOption: NSObject {
    var bUserName: Bool = false
    var bTakenDate: Bool = false
    var bUploadDate: Bool = false
    var bDeletedDate: Bool = false

    var takenDateFrom: TimeInterval?
    var takenDateTo: TimeInterval?
    var uploadDateFrom: TimeInterval?
    var uploadDateTo: TimeInterval?
    var deletedDateFrom: TimeInterval?
    var deletedDateTo: TimeInterval?

    var userid: String?
    var userName: String?
    var email: String?
    
    func copy() -> SearchOption {
        let tempOptions = SearchOption()
        
        tempOptions.bTakenDate = self.bTakenDate
        tempOptions.bUploadDate = self.bUploadDate
        tempOptions.bUserName = self.bUserName
        
        tempOptions.takenDateFrom = self.takenDateFrom
        tempOptions.takenDateTo = self.takenDateTo
        tempOptions.uploadDateFrom = self.uploadDateFrom
        tempOptions.uploadDateTo = self.uploadDateTo
        
        tempOptions.userid = self.userid
        tempOptions.userName = self.userName
        tempOptions.email = self.email

        return tempOptions
    }
}

class Global: NSObject {
    static let sharedFolderName = "Ohana Sync"
    
    static var user: GIDGoogleUser?
    static var userid: String?
    static var origin_name: String?
    static var username: String?
    static var email: String?
    
    static var date_format_list: [String] = [ "MM/dd/YYYY", "dd/MM/YYYY", "YYYY/MM/dd" ]
    static var date_format_index: Int = 0   // date format index (settings)
    static var date_format: String?         // date format string
    
    static var time_format_list: [String] = [ "HH:mm:ss", "h:mm:ss a" ]
    static var time_format_index: Int = 0   // time format index (settings)
    static var time_format: String?         // time format string
    
    static var bAutoUpload: Bool = true  // Setting (Auto Upload enabled)
    static var bNeedToSynchronize: Bool = false // check synchronizing

    static var needRefreshLocal = true
    static var needRefreshStorage = true
    static var needDoneSelectionAtHome = false    // exit from photo selection at Home Tab (download complete)

    static var sharedCloudPhotos: [FSPhotoInfo]?
    static var selectedCloudPhotos: [FSPhotoInfo]?
    static var helpCrunchInited: Bool = false
    static var searchOption: SearchOption = SearchOption()
    static var notificationOption: SearchOption = SearchOption()

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
    
    static func getThumbnail(image: UIImage) -> UIImage {
        let imageData = image.jpegData(compressionQuality: 1.0)!
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 300] as CFDictionary
        let source = CGImageSourceCreateWithData(imageData as CFData, nil)!
        let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options)!
        let thumbnail = UIImage(cgImage: imageReference)

        return thumbnail
    }
    
    static func doLogout() {
        GIDSignIn.sharedInstance()?.signOut()
        
        Global.userid = nil
        Global.username = nil
        Global.email = nil
    }
    
    static func getString(fromDate: Date, withFormat format:String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format

        let dateString = formatter.string(from: fromDate)

        return dateString
    }
    
    static func getDateTimeString(interval: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: interval)
        let formatter = DateFormatter()
        
        let date_format = Global.date_format ?? Global.date_format_list[0]
        let time_format = Global.time_format ?? Global.time_format_list[0]

        formatter.dateFormat = date_format + " " + time_format
        let dateString = formatter.string(from: date)

        return dateString
    }
    
    static func getDateStartInterval(interval: TimeInterval?) -> TimeInterval? {
        if interval == nil {
            return nil
        }
        
        let date = Date(timeIntervalSince1970: interval!)
        let bdate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date)
        
        return bdate?.timeIntervalSince1970
    }
    
    static func getDateEndInterval(interval: TimeInterval?) -> TimeInterval? {
        if interval == nil {
            return nil
        }
        
        let date = Date(timeIntervalSince1970: interval!)
        let bdate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date)

        return bdate?.timeIntervalSince1970
    }
}

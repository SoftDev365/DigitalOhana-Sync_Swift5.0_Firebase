//
//  GDModuleSync.swift
//  Google Drive Synchronous Module
//
//  Created by Admin on 12/26/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

class GDModuleSync: NSObject {
            
    static func getDefaultFolderID() -> String? {
        
        if GDModule.defaultFolderID != nil {
            return GDModule.defaultFolderID
        }

        var result: String? = nil
        var bProcessing = true
        
        GDModule.getDefaultFolderID { (folderID) in
            result = folderID
            bProcessing = false
        }

        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.001)
        }

        return result
    }
    
    // search file or folder
    static func checkExists(fileTitle: String) -> Bool {
        
        var result: Bool = false
        var bProcessing = true
        
        GDModule.checkExists(fileTitle: fileTitle) { (fileID, _) in
            if fileID != nil {
                result = true
            }
            bProcessing = false
        }

        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.001)
        }

        return result
    }

    static func downloadImage(fileID: String) -> UIImage? {
        var result: UIImage? = nil
        var bProcessing = true
        
        GDModule.downloadImage(fileID: fileID) { (_, image) in
            result = image
            bProcessing = false
        }

        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.001)
        }

        return result
    }
    
    static func uploadImage(_ image: UIImage, fileTitle: String, folderID: String) -> Bool {
        var result: Bool = false
        var bProcessing = true
        
        GDModule.uploadImage(image, fileTitle: fileTitle, folderID: folderID) { (success) in
            result = success
            bProcessing = false
        }

        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.001)
        }

        return result
    }    
}

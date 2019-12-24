//
//  GSModuleSync.swift
//  Google Sotrage Module (Synchronous)
//
//  Created by Admin on 12/6/19.
//  Copyright © 2019 Admin. All rights reserved.
//
//  Google Storage Module

import UIKit
import Firebase
import FirebaseStorage
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

class GSModuleSync: NSObject {
    
    static func downloadImageFile(_ file: StorageReference ) -> UIImage? {
        
        var imgResult: UIImage? = nil
        var bProcessing = true
        
        GSModule.downloadImageFile(file) { (image) in
            imgResult = image
            bProcessing = false
        }

        // block while download processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        return imgResult
    }

    static func downloadImageFile(cloudFileID: String, folderPath: String) -> UIImage? {
        var imgResult: UIImage? = nil
        var bProcessing = true
        
        GSModule.downloadImageFile(cloudFileID: cloudFileID, folderPath: folderPath) { (_, image) in
            imgResult = image
            bProcessing = false
        }

        // block while download processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.01)
        }

        return imgResult
    }
    
    static func uploadFile(cloudFileID: String, folderPath: String, data: Data) -> Bool {

        var bResult = false
        var bProcessing = true
        
        GSModule.uploadFile(cloudFileID: cloudFileID, folderPath: folderPath, data: data) { (success) in
            bResult = success
            bProcessing = false
        }
        
        // block while upload processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        return bResult
    }
    
    static func uploadFile(cloudFileID: String, folderPath: String, fileURL: URL) -> Bool {
        do {
            let data = try Data(contentsOf: fileURL)
            return uploadFile(cloudFileID: cloudFileID, folderPath: folderPath, data: data)
        } catch {
            return false
        }
    }
    
    static func deleteFile(file: StorageReference) -> Bool {
        var bResult = false
        var bProcessing = true

        GSModule.deleteFile(file: file) { (success) in
            bResult = success
            bProcessing = false
        }
        
        // block while delete processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        return bResult
    }
    
    static func deleteFile(cloudFileID: String, parentFolder: String) -> Bool {
        var bResult = false
        var bProcessing = true

        GSModule.deleteFile(cloudFileID: cloudFileID, parentFolder: parentFolder) { (success) in
            bResult = success
            bProcessing = false
        }

        // block while delete processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        return bResult
    }
}

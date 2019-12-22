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
    static let imageCache = NSCache<NSString, UIImage>()
    
    static func downloadImageFile(_ file: StorageReference ) -> UIImage? {
        if let cachedImage = self.imageCache.object(forKey: file.fullPath as NSString)  {
            return cachedImage
        }
        
        var imgResult: UIImage? = nil
        var bProcessing = true
        file.getData(maxSize: 50 * 1024 * 1024) { data, error in
            bProcessing = false
            if let error = error {
                debugPrint(error)
            } else {
                let image = UIImage(data: data!)
                if image != nil {
                    self.imageCache.setObject(image!, forKey: file.fullPath as NSString)
                }
                imgResult = image
            }
        }

        // block while download processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 10)
        }
        
        return imgResult
    }

    static func downloadImageFile(fileID:String, folderPath: String) -> UIImage? {
        let filePath = folderPath + "/" + fileID + ".jpg"
        // Get a reference to the storage service using the default Firebase App
        let storage = Storage.storage()
        // Create a storage reference from our storage service
        let storageRef = storage.reference()
        // Create a reference to the file you want to download
        let fileRef = storageRef.child(filePath)
        
        return downloadImageFile(fileRef)
    }
    
    static func uploadFile( name: String, folderPath: String, data: Data ) -> Bool {

        let filePath = folderPath + "/" + name
        // Get a reference to the storage service using the default Firebase App
        let storage = Storage.storage()
        // Create a storage reference from our storage service
        let storageRef = storage.reference()
        // Create a reference to the file you want to upload
        let fileRef = storageRef.child(filePath)

        var bResult = false
        var bProcessing = true
        
        // Upload the file to the path "images/rivers.jpg"
        let _ = fileRef.putData(data, metadata: nil) { (metadata, error) in
            bProcessing = false
            if let error = error {
                debugPrint(error)
                bResult = false
            } else {
                bResult = true
            }
        }
        
        // block while upload processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 10)
        }
        
        return bResult
    }
    
    static func uploadFile(name: String, folderPath: String, fileURL: URL) -> Bool {
        do {
            let data = try Data(contentsOf: fileURL)
            return uploadFile(name: name, folderPath: folderPath, data: data)
        } catch {
            return false
        }
    }
    
    static func deleteFile(file: StorageReference) -> Bool {
        var bResult = false
        var bProcessing = true

        file.delete { (error) in
            bProcessing = false
            if error != nil {
                debugPrint(error!)
                bResult = false
            } else {
                bResult = true
            }
        }
        
        // block while delete processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 10)
        }
        
        return bResult
    }
    
    static func deleteFile(name: String, parentFolder: String) -> Bool {

        let filePath = parentFolder + "/" + name
        // Get a reference to the storage service using the default Firebase App
        let storage = Storage.storage()
        // Create a storage reference from our storage service
        let storageRef = storage.reference()
        // Create a reference to the file you want to upload
        let fileRef = storageRef.child(filePath)

        return deleteFile(file: fileRef)
    }
}

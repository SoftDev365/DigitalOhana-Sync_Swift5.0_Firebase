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
        var bDownload = false
        file.getData(maxSize: 50 * 1024 * 1024) { data, error in
            bDownload = true
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
        
        while bDownload == false {
            Thread.sleep(forTimeInterval: 10)
        }
        
        return imgResult;
    }

    static func downloadImageFile(fileID:String, folderPath: String, onCompleted: @escaping (String, UIImage?) -> ()) {
        // check cached image
        if let cachedImage = self.imageCache.object(forKey: fileID as NSString)  {
            onCompleted(fileID, cachedImage)
        }

        let filePath = folderPath + "/" + fileID + ".jpg"
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let fileRef = storageRef.child(filePath)

        // Download in memory with a maximum allowed size of 1MB (50 * 1024 * 1024 bytes)
        fileRef.getData(maxSize: 50 * 1024 * 1024) { data, error in
            if let error = error {
                debugPrint(error)
                onCompleted(fileID, nil)
            } else {
                let image = UIImage(data: data!)
                if image != nil {
                    self.imageCache.setObject(image!, forKey: fileID as NSString)
                }
                onCompleted(fileID, image)
            }
        }
    }
    
    static func uploadFile(
        name: String,
        folderPath: String,
        data: Data,
        completion: @escaping (Bool) -> Void) {

        let filePath = folderPath + "/" + name

        // Get a reference to the storage service using the default Firebase App
        let storage = Storage.storage()
        // Create a storage reference from our storage service
        let storageRef = storage.reference()
        // Create a reference to the file you want to upload
        let fileRef = storageRef.child(filePath)

        // Upload the file to the path "images/rivers.jpg"
        let _ = fileRef.putData(data, metadata: nil) { (metadata, error) in
            if let error = error {
                debugPrint(error)
                completion(false)
            } else {
                completion(true)
            }
            /*
            if metadata != nil {
                //auth.email
                let newMetadata = StorageMetadata()
                var email = Global.user!.profile.email
                var name = Global.user!.profile.name
                
                if email == nil {
                    email = ""
                }
                if name == nil {
                    name = ""
                }
                newMetadata.customMetadata = ["ownerEmail": email!, "ownerName": name!]
                fileRef.updateMetadata(newMetadata) { metadata, error in
                    if let error = error {
                        // Uh-oh, an error occurred!
                        debugPrint(error)
                        completion(false)
                    } else {
                        // metadata.contentType should be nil
                        completion(true)
                    }
                }
            } else {
                // Uh-oh, an error occurred!
                completion(false)
            }*/
        }
    }
    
    static func uploadFile(
        name: String,
        folderPath: String,
        fileURL: URL,
        completion: @escaping (Bool) -> Void) {
        
        do {
            let data = try Data(contentsOf: fileURL)
            uploadFile(name: name, folderPath: folderPath, data: data, completion: completion)
        } catch {
            completion(false)
        }
    }
    
    static func createFolder(
        name: String,
        parentFolder: String,
        completion: @escaping (Bool) -> Void) {
        
        let data = Data()
        let folderPath = parentFolder + "/" + name
        let filePath = folderPath + "/empty_file_for_create_folder.dat"

        // Get a reference to the storage service using the default Firebase App
        let storage = Storage.storage()
        // Create a storage reference from our storage service
        let storageRef = storage.reference()
        // Create a reference to the file you want to upload
        let fileRef = storageRef.child(filePath)

        // Upload the file to the path "images/rivers.jpg"
        fileRef.putData(data, metadata: nil) { (metadata, error) in
            if error != nil {
                // Uh-oh, an error occurred!
                completion(false)
                return
            }
            
            completion(true)
            
            /*
            fileRef.delete { (error) in
                if error != nil {
                    debugPrint(error!)
                }
                completion(true)
            }*/
        }
    }
    
    static func deleteFile(
        file: StorageReference,
        completion: @escaping (Bool) -> Void) {

        file.delete { (error) in
            if error != nil {
                debugPrint(error!)
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    static func deleteFile(
        name: String,
        parentFolder: String,
        completion: @escaping (Bool) -> Void) {

        let filePath = parentFolder + "/" + name
        // Get a reference to the storage service using the default Firebase App
        let storage = Storage.storage()
        // Create a storage reference from our storage service
        let storageRef = storage.reference()
        // Create a reference to the file you want to upload
        let fileRef = storageRef.child(filePath)

        fileRef.delete { (error) in
            if error != nil {
                debugPrint(error!)
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}

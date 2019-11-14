//
//  GDModule.swift
//  SharePhoto
//
//  Created by Admin on 11/6/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

struct StorageItem {
    var isFolder: Bool
    var name: String
    var file: StorageReference
    
    init(isFolder: Bool, name: String, file: StorageReference) {
        self.isFolder = isFolder
        self.name = name
        self.file = file
    }
}

class GSModule: NSObject {
    static var user: GIDGoogleUser?
    static let imageCache = NSCache<NSString, UIImage>()
    
    static func getImageFileList(_ folderName: String, onCompleted: @escaping ([StorageItem])->()) {
        // Get a reference to the storage service using the default Firebase App
        let storage = Storage.storage()
        // Create a storage reference from our storage service
        let storageRef = storage.reference()
        //let centralRef = storageRef.child(self.folderPath!)
        let folderRef = storageRef.child(folderName)

        folderRef.listAll() { (result, error) in
            var listFiles = [StorageItem]()
            if let error = error {
                debugPrint(error)
            } else {
                
                for prefix in result.prefixes {
                    let folder = StorageItem(isFolder: true, name: prefix.name, file: prefix)
                    listFiles.append(folder)
                }
                
                for item in result.items {
                    let filename = item.name as NSString
                    let fileExt = filename.pathExtension.lowercased()
                    if fileExt != "png" && fileExt != "jpg" {
                        continue
                    }

                    let file = StorageItem(isFolder: false, name: item.name, file: item)
                    listFiles.append(file)
                }
            }
            
            onCompleted(listFiles)
        }
    }
    
    static func downloadImageFile(_ file: StorageReference, onCompleted: @escaping (UIImage?) -> ()) {
        // check cached image
        if let cachedImage = self.imageCache.object(forKey: file.fullPath as NSString)  {
            onCompleted(cachedImage)
        }

        // Download in memory with a maximum allowed size of 1MB (50 * 1024 * 1024 bytes)
        file.getData(maxSize: 50 * 1024 * 1024) { data, error in
            if let error = error {
                // Uh-oh, an error occurred!
                debugPrint(error)
            } else {
                // Data for "images/island.jpg" is returned
                let image = UIImage(data: data!)
                if image != nil {
                    self.imageCache.setObject(image!, forKey: file.fullPath as NSString)
                }
                onCompleted(image)
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
        let uploadTask = fileRef.putData(data, metadata: nil) { (metadata, error) in
            if metadata != nil {
                // Uh-oh, an error occurred!
                completion(false)
                return
            }

            completion(true)
        }
        
        uploadTask.resume()
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

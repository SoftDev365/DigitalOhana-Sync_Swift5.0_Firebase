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

class GSModule: NSObject {
    static var user: GIDGoogleUser?
    static let imageCache = NSCache<NSString, UIImage>()
    
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
            // Metadata contains file metadata such as size, content-type.
            //let size = metadata.size
            
            completion(true)

            /*
            // You can also access to download URL after upload.
            fileRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    return
                }
            }*/
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
               
        uploadFile(name: "empty_folder.dat", folderPath: folderPath, data: data, completion: completion)
    }
}

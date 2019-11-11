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
}

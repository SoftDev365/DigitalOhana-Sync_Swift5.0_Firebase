//
//  SyncModule.swift
//  SharePhoto
//
//  Created by Admin on 11/29/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import Photos

class SyncModule: NSObject {
    static let sharedFolderName = "central"

    static func regiserPhotoToFirestore(asset: PHAsset, onCompleted: @escaping (Bool, String?) -> ()) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        var dateCreate = ""
        if asset.creationDate != nil {
            dateCreate = df.string(from: asset.creationDate!)
        } else {
            dateCreate = df.string(from: Date())
        }
            
        GFSModule.registerPhoto(createDate: dateCreate) { (success, id) in
            onCompleted(success, id)
        }
    }
    
    static func uploadPhoto(asset: PHAsset, onCompleted:@escaping (Bool) -> ()) {
        regiserPhotoToFirestore(asset: asset) { (success, documentID) in
            if !success {
                onCompleted(false)
                return
            }

            let filename = documentID! + ".jpg"
            let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            PHCachingImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil) { (image, _) in
                guard let image = image else { return }
                let imageData = image.jpegData(compressionQuality: 1.0)

                GSModule.uploadFile(name: filename, folderPath: self.sharedFolderName, data: imageData!) { (success) in
                    onCompleted(success)

                    if success {
                        GFSModule.updatePhotoToValid(photoID: documentID!) { (success) in
                            // success update valid to true
                        }
                    }
                }
            }
        }
    }
}

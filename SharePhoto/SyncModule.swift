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
        // register photo to firestore & get document id (primary key)
        regiserPhotoToFirestore(asset: asset) { (success, documentID) in
            if !success {
                debugPrint("-----register photo to firestore failed------")
                onCompleted(false)
                return
            }

            let filename = documentID! + ".jpg"
            let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            
            // extract image data
            PHCachingImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil) { (image, info) in
                // skip twice calls
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if isDegraded {
                   return
                }
                
                // check image is not null
                guard let image = image else {
                    debugPrint("-----extract image from asset failed ------")
                    onCompleted(false)
                    return
                }
                let imageData = image.jpegData(compressionQuality: 1.0)

                // upload image data to cloud storage
                GSModule.uploadFile(name: filename, folderPath: self.sharedFolderName, data: imageData!) { (success) in
                    
                    if success {
                        // register to local sqlite db (local filename & firestore id)
                        if SqliteManager.insertFileInfo(isMine: true, fname: asset.localIdentifier, fsID: documentID!) == true {
                            // update firestore valid flag to true
                            GFSModule.updatePhotoToValid(photoID: documentID!) { (success) in
                                // success update valid to true
                                onCompleted(success)
                            }
                        } else {
                            debugPrint("-----register photo to local db failed------")
                            onCompleted(success)
                        }
                    } else {
                        debugPrint("----- uploading image data to cloud storage failed ------")
                        onCompleted(success)
                    }
                }
            }
        }
    }
    
    static func checkPhotoIsUploaded(fname: String) -> Bool {
        return SqliteManager.checkPhotoIsUploaded(fname: fname)
    }
    
    static func checkPhotoIsDownloaded(fileID: String) -> Bool {
        return SqliteManager.checkPhotoIsDownloaded(fileID: fileID)
    }
    
    static func downloadImage(photoInfo: [String:Any], image: UIImage, onCompleted: @escaping(Bool)->()) {

        PHModule.addPhotoToFamilyAssets(image) { (bSuccess, localIdentifier) in
            if bSuccess == false {
                onCompleted(false)
            } else {
                
                //"create",
                //"upload",
                //"userid",
                //"email,
                //"name",
                //"valid": false
                let fsID = photoInfo["id"] as! String
                let data = photoInfo["data"] as! [String: Any]
                let email = data["email"] as! String
                
                if email == Global.email {
                    _ = SqliteManager.insertFileInfo(isMine: true, fname: localIdentifier!, fsID: fsID)
                } else {
                    _ = SqliteManager.insertFileInfo(isMine: false, fname: localIdentifier!, fsID: fsID)
                }
                
                onCompleted(true)
            }
        }
    }

}

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

    static func registerPhotoToFirestore(asset: PHAsset, onCompleted: @escaping (Bool, String?) -> ()) {
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
    
    static func registerPhotoToFirestoreSync(asset: PHAsset) -> String? {
        var result: String? = nil
        var bProcessing = true
        
        SyncModule.registerPhotoToFirestore(asset: asset) { (success, documentID) in
            result = documentID
            bProcessing = false
        }
        
        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.005)
        }

        return result
    }
    
    static func uploadPhoto(image: UIImage, onCompleted:@escaping (Bool) -> ()) {
        PHModule.addPhotoToFamilyAssets(image) { (bSuccess, localIdentifier) in
            if bSuccess == false {
                onCompleted(false)
            } else {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier!], options: nil)
                let asset = assets[0]

                uploadPhoto(asset: asset, onCompleted: onCompleted)
            }
        }
    }
    
    static func uploadPhoto(asset: PHAsset, onCompleted:@escaping (Bool) -> ()) {
        // register photo to firestore & get document id (primary key)
        registerPhotoToFirestore(asset: asset) { (success, documentID) in
            if !success {
                debugPrint("-----register photo to firestore failed------")
                onCompleted(false)
                return
            }

            let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            options.progressHandler = {  (progress, error, stop, info) in
                print("progress: \(progress)")
            }

            //let size = UIScreen.main.bounds.size
            PHCachingImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { (image, info) in
                
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
                GSModule.uploadFile(cloudFileID: documentID!, folderPath: self.sharedFolderName, data: imageData!) { (success) in
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
    
    static func uploadPhotoSync(asset: PHAsset) -> Bool {
        var bResult: Bool = false
        var bProcessing = true
        
        SyncModule.uploadPhoto(asset: asset) { (success) in
            bResult = success
            bProcessing = false
        }
        
        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.005)
        }

        return bResult
    }
    
    static func checkPhotoIsUploaded(localIdentifier: String) -> Bool {
        return SqliteManager.checkPhotoIsUploaded(localIdentifier: localIdentifier)
    }
    
    static func checkPhotoIsDownloaded(cloudFileID: String) -> Bool {
        return SqliteManager.checkPhotoIsDownloaded(cloudFileID: cloudFileID)
    }
    
    // download one file by async
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
    
    // download batch selected photos from cloud to local (result: download, skip, fail)
    static func downloadSelectedPhotosToLocal(onCompleted: @escaping(Int, Int, Int)->()) {

        var nDownloaded = 0
        var nSkipped = 0
        var nFailed = 0
        
        guard let photoInfos = Global.selectedCloudPhotos else {
            onCompleted(0, 0, 0)
            return
        }

        DispatchQueue.global(qos: .background).async {
            for photoInfo in photoInfos {
                let fsID = photoInfo["id"] as! String
                if checkPhotoIsDownloaded(cloudFileID: fsID) {
                    nSkipped += 1
                    continue
                }
                
                let image = GSModuleSync.downloadImageFile(cloudFileID: fsID, folderPath: self.sharedFolderName)
                if image == nil {
                    nFailed += 1
                    continue
                }
                
                if let localIdentifier = PHModuleSync.addPhotoToFamilyAssets(image!) {
                    let data = photoInfo["data"] as! [String: Any]
                    let email = data["email"] as! String
                    if email == Global.email {
                        _ = SqliteManager.insertFileInfo(isMine: true, fname: localIdentifier, fsID: fsID)
                    } else {
                        _ = SqliteManager.insertFileInfo(isMine: false, fname: localIdentifier, fsID: fsID)
                    }
                    nDownloaded += 1
                } else {
                    nFailed += 1
                }
            }
            
            DispatchQueue.main.async {
                onCompleted(nDownloaded, nSkipped, nFailed)
            }
        }
    }
    
    // result (upload, skip, fail count)
    static func uploadSelectedLocalPhotos(assets: [PHAsset], onCompleted: @escaping(Int, Int, Int)->()) {
        DispatchQueue.global(qos: .background).async {
            var nUpload: Int = 0
            var nSkip: Int = 0
            var nFail: Int = 0
            
            for asset in assets {
                if SyncModule.checkPhotoIsUploaded(localIdentifier: asset.localIdentifier) == true {
                    nSkip += 1
                } else if SyncModule.uploadPhotoSync(asset: asset) == true {
                    nUpload += 1
                } else {
                    nFail += 1
                }
            }

            DispatchQueue.main.async {
                onCompleted(nUpload, nSkip, nFail)
            }
        }
    }
    
    // delete photos (result: deleted, failed)
    static func deleteSelectedPhotosFromCloud(photoInfos: [[String:Any]], onCompleted: @escaping(Int, Int)->()) {
        DispatchQueue.global(qos: .background).async {
            var nUpload: Int = 0
            var nFail: Int = 0
            
            for photoInfo in photoInfos {
                let fsID = photoInfo["id"] as! String
                
                // delete photo from list (firestore database)
                if GFSModuleSync.deletePhoto(photoID: fsID) == true {
                    // delete photo file from storage
                    // block it, remain photo file for RPi frame (shared file)
                    // _ = GSModuleSync.deleteFile(cloudFileID: fsID, parentFolder: self.sharedFolderName)

                    // delete from local database
                    SqliteManager.deletePhotoBy(cloudFileID: fsID)

                    nUpload += 1
                } else {
                    nFail += 1
                }
            }

            DispatchQueue.main.async {
                onCompleted(nUpload, nFail)
            }
        }
    }
}

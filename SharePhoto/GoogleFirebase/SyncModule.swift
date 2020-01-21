//
//  SyncModule.swift
//  SharePhoto
//
//  Created by Admin on 11/29/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import Photos
import GoogleAPIClientForREST

class SyncModule: NSObject {
    static let sharedFolderName = "central"

    static func registerPhotoToFirestore(asset: PHAsset, onCompleted: @escaping (Bool, String?) -> ()) {
        let dtCreated = asset.creationDate ?? Date()
        let taken = dtCreated.timeIntervalSince1970
        
        let info = FSPhotoInfo()
        
        info.taken = taken
        info.sourceType = SourceType.asset
        info.sourceID = asset.localIdentifier
        info.size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        //info.tag = asset.location

        GFSModule.registerPhoto(info: info) { (success, id) in
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
    
    static func registerPhotoToFirestore(driveFile: GTLRDrive_File, onCompleted: @escaping (Bool, String?) -> ()) {
        let dtCreated = driveFile.createdTime?.date ?? Date()
        let taken = dtCreated.timeIntervalSince1970

        let info = FSPhotoInfo()

        info.taken = taken
        info.sourceType = SourceType.drive
        info.sourceID = driveFile.identifier ?? ""
        
        //driveFile.imageMediaMetadata!.width!.int32Value
        //info.size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        //info.tag = asset.location
        
        GFSModule.registerPhoto(info: info) { (success, id) in
            onCompleted(success, id)
        }
    }
    
    static func registerPhotoToFirestoreSync(driveFile: GTLRDrive_File) -> String? {
        var result: String? = nil
        var bProcessing = true

        SyncModule.registerPhotoToFirestore(driveFile: driveFile) { (success, documentID) in
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
    
    static func uploadImage(_ image: UIImage, withDocumentID cloudDocumentID: String, onCompleted:@escaping (Bool) -> ()) {
        let thumbnail = Global.getThumbnail(image: image)
        let thumbData = thumbnail.jpegData(compressionQuality: 1.0)
        let thumbFileID = cloudDocumentID + "_thumb"

        // first upload thumbnail image data to cloud storage
        GSModule.uploadFile(cloudFileID: thumbFileID, folderPath: self.sharedFolderName, data: thumbData!) { (success) in
            if success == true {
                let imageData = image.jpegData(compressionQuality: 1.0)
                
                // upload image data to cloud storage
                GSModule.uploadFile(cloudFileID: cloudDocumentID, folderPath: self.sharedFolderName, data: imageData!) { (success) in
                    onCompleted(success)
                }
            } else {
                onCompleted(false)
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

            options.progressHandler = { (progress, error, stop, info) in
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

                // upload image data to cloud storage
                self.uploadImage(image, withDocumentID: documentID!) { (success) in
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
    static func downloadImage(photoInfo: FSPhotoInfo, image: UIImage, onCompleted: @escaping(Bool)->()) {

        PHModule.addPhotoToFamilyAssets(image) { (bSuccess, localIdentifier) in
            if bSuccess == false {
                onCompleted(false)
            } else {
                let fsID = photoInfo.id
                let email = photoInfo.email
                
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
                let fsID = photoInfo.id
                
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
                    let email = photoInfo.email
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
    static func deleteSelectedPhotosFromCloud(photoInfos: [FSPhotoInfo], onCompleted: @escaping(Int, Int, Int)->()) {
        DispatchQueue.global(qos: .background).async {
            var nUpload: Int = 0
            var nSkip: Int = 0
            var nFail: Int = 0
            
            for photoInfo in photoInfos {
                let fsID = photoInfo.id
                let email = photoInfo.email
                
                // photo was uploaded by other person
                if Global.email != email {
                    nSkip += 1
                } else if GFSModuleSync.deletePhoto(photoID: fsID) == true {
                    // delete photo from list (firestore database)
                    
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
                onCompleted(nUpload, nSkip, nFail)
            }
        }
    }

    // download batch selected photos from cloud to drive (result: download, skip, fail)
    static func downloadSelectedPhotosToDrive(onCompleted: @escaping(Int, Int, Int)->()) {

        var nDownloaded = 0
        var nSkipped = 0
        var nFailed = 0
        
        guard let photoInfos = Global.selectedCloudPhotos else {
            onCompleted(0, 0, 0)
            return
        }

        DispatchQueue.global(qos: .background).async {
            
            guard let defFolderID = GDModuleSync.getDefaultFolderID() else {
                DispatchQueue.main.async {
                    onCompleted(0, 0, photoInfos.count)
                }
                return
            }
            
            for photoInfo in photoInfos {
                let fsID = photoInfo.id
                
                if GDModuleSync.checkExists(fileTitle: fsID) {
                    nSkipped += 1
                    continue
                }
                
                let image = GSModuleSync.downloadImageFile(cloudFileID: fsID, folderPath: self.sharedFolderName)
                if image == nil {
                    nFailed += 1
                    continue
                }
                
                if GDModuleSync.uploadImage(image!, fileTitle: fsID, folderID: defFolderID) == true {
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
    
    static func uploadPhoto(driveFile: GTLRDrive_File, onCompleted:@escaping (Bool) -> ()) {
        // register photo to firestore & get document id (primary key)
        registerPhotoToFirestore(driveFile: driveFile) { (success, documentID) in
            if !success {
                debugPrint("-----register photo to firestore failed------")
                onCompleted(false)
                return
            }
            
            GDModule.downloadImage(fileID: driveFile.identifier!) { (fileID, image) in
                // check image is not null
                guard let image = image else {
                    debugPrint("-----download image from drive failed ------")
                    onCompleted(false)
                    return
                }
                
                self.uploadImage(image, withDocumentID: documentID!) { (success) in
                    if success {
                        GFSModule.updatePhotoToValid(photoID: documentID!) { (success) in
                            // success update valid to true
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
    
    static func uploadPhotoSync(driveFile: GTLRDrive_File) -> Bool {
        var bResult: Bool = false
        var bProcessing = true
        
        SyncModule.uploadPhoto(driveFile: driveFile) { (success) in
            bResult = success
            bProcessing = false
        }

        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.005)
        }

        return bResult
    }
    
    static func checkPhotoIsUploaded(driveFile: GTLRDrive_File) -> Bool {
        guard let sharedPhotos = Global.sharedCloudPhotos else { return false }
        
        guard let fileName = driveFile.name else { return false }
        guard let name = fileName.split(separator: ".").map(String.init).first else { return false }
        
        for photoInfo in sharedPhotos {
            // check if this drive photo downloaded from cloud
            if photoInfo.id == name {
                return true
            }
        
            // check if uploaded from my drive to cloud
            if photoInfo.email == Global.email! {
                if photoInfo.sourceType == .drive && photoInfo.sourceID == driveFile.identifier {
                    return true
                }
            }
        }
        
        return false
    }
    
    static func checkPhotoIsDownloadedToDrive(cloudFileID: String) -> Bool {
        return false
    }
    
    // result (upload, skip, fail count)
    static func uploadSelectedDrivePhotos(files: [GTLRDrive_File], onCompleted: @escaping(Int, Int, Int)->()) {
        DispatchQueue.global(qos: .background).async {
            var nUpload: Int = 0
            var nSkip: Int = 0
            var nFail: Int = 0

            for file in files {
                if SyncModule.checkPhotoIsUploaded(driveFile: file) == true {
                    nSkip += 1
                } else if SyncModule.uploadPhotoSync(driveFile: file) == true {
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
    
    //================================================================================================================//
    
    static func uploadPhoto(localPath: String, onCompleted:@escaping (Bool) -> ()) {
        if let image = UIImage(contentsOfFile: localPath) {
            SyncModule.uploadPhoto(image: image, onCompleted: onCompleted)
        } else {
            onCompleted(false)
        }
    }
    
    static func uploadPhotoSync(localPath: String) -> Bool {
        var bResult: Bool = false
        var bProcessing = true
        
        SyncModule.uploadPhoto(localPath: localPath) { (success) in
            bResult = success
            bProcessing = false
        }

        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.005)
        }

        return bResult
    }
    
    // result (upload, skip, fail count)
    static func uploadLocalPhotos(files: [String], onCompleted: @escaping(Int, Int, Int)->()) {
        DispatchQueue.global(qos: .background).async {
            var nUpload: Int = 0
            let nSkip: Int = 0
            var nFail: Int = 0

            for file in files {
                if SyncModule.uploadPhotoSync(localPath: file) == true {
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

}

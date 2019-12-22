//
//  PHModuleSync.swift
//  Photo Module Synchronous
//
//  Created by Admin on 12/22/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import Photos

class PHModuleSync: NSObject {
    
    static let albumTitle = "Ohana Memory Sync"
    
    static func addPhotoToAlbumCollection(album: PHAssetCollection, imagePhoto: UIImage) -> String? {
        
        var bResult = false
        var bProcessing = true

        debugPrint("---- write start -----")
        var assetPlaceholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: imagePhoto)
            assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset!
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            let enumeration: NSArray = [assetPlaceholder!]
            albumChangeRequest!.addAssets(enumeration)
        }, completionHandler: { (success, error) in
            debugPrint("---- write complete -----\n")
            bProcessing = false
            if success {
                bResult = true
            } else {
                bResult = false
            }
        })
        
        // block while save processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.005)
        }
        
        debugPrint("---- write exit -----\n")

        if bResult {
            return assetPlaceholder?.localIdentifier
        } else {
            return nil
        }
    }
    
    static func addPhotoToFamilyAssets(_ imagePhoto: UIImage) -> String? {
        let familyAlbum = PHModule.fetchFamilyAlbumCollection()
        if let album = familyAlbum {
            return addPhotoToAlbumCollection(album: album, imagePhoto: imagePhoto)
        } else {
            return nil
        }
    }
    
    func loadPhotoFromAsset(asset: PHAsset) -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        //options.deliveryMode = .opportunistic
        options.resizeMode = .none
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true

        options.progressHandler = {  (progress, error, stop, info) in
            print("progress: \(progress)")
        }
        
        var imgResult: UIImage? = nil
        var bProcessing = true
        
        //let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        let size = UIScreen.main.bounds.size
        PHCachingImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { (image, info) in
            // skip down graded image
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            if isDegraded {
               return
            }

            bProcessing = false
            imgResult = image
        }
        
        // block while save processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.005)
        }
        
        return imgResult
    }
}

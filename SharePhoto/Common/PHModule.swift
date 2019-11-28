//
//  PHModule.swift
//  SharePhoto
//
//  Created by Admin on 11/26/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import Photos

class PHModule: NSObject {
    
    static let albumTitle = "Is"
    
    // get the assets in a collection
    static func getAssets(fromCollection collection: PHAssetCollection) -> PHFetchResult<PHAsset> {
        let photosOptions = PHFetchOptions()
        photosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        photosOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        return PHAsset.fetchAssets(in: collection, options: photosOptions)
    }
    
    static func fetchFamilyAlbumCollection() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()

        fetchOptions.predicate = NSPredicate(format: "title = %@", albumTitle)
        // get the albums list
        //let albumList = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        let albumList = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        // you can access the number of albums with
        let albumCount = albumList.count
        if albumCount <= 0 {
            return nil
        }

        // individual objects with
        let familyAlbum = albumList.object(at: 0)
        
        return familyAlbum
    }
    
    /*
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            //showAlertWith(title: "Save error", message: error.localizedDescription)
            print(error)
        } else {
            //showAlertWith(title: "Saved!", message: "Your image has been saved to your photos.")
            fetchFamilyAlbumPhotos()
        }
    }*/
    
    static func addPhotoToAsset(_ imagePhoto: UIImage, completion: @escaping (Bool) -> Void) {
        //UIImageWriteToSavedPhotosAlbum(tempImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        let familyAlbum = self.fetchFamilyAlbumCollection()
        
        var assetPlaceholder: PHObjectPlaceholder?

        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: imagePhoto)
            assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset!
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: familyAlbum!)
            let enumeration: NSArray = [assetPlaceholder!]
            albumChangeRequest!.addAssets(enumeration)
        }, completionHandler: { (success, error) in
            NSLog("Creation of folder -> %@", (success ? "Success":"Error!"))
            //self.albumFound = (success ? true:false)
            if(success){
                //let collection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [assetPlaceholder!.localIdentifier], options: nil)
                //self.assetCollection = collection.firstObject as! PHAssetCollection
            }

            completion(success)
        })
    }
    
    static func deleteAssets(_ assets: NSArray, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges( {
            PHAssetChangeRequest.deleteAssets(assets)},
            completionHandler: { bSuccess, error in
                completion(bSuccess)
        })
    }
}

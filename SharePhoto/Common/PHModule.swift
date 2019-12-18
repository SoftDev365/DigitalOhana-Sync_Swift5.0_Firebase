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
    
    static let albumTitle = "Ohana Memory Sync"
    
    static func createAlbum(withTitle title: String, completionHandler: @escaping (PHAssetCollection?) -> ()) {
        DispatchQueue.global(qos: .background).async {
            var placeholder: PHObjectPlaceholder?

            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
                placeholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { (created, error) in
                var album: PHAssetCollection?
                if created {
                    let collectionFetchResult = placeholder.map { PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [$0.localIdentifier], options: nil) }
                    album = collectionFetchResult?.firstObject
                }

                completionHandler(album)
            })
        }
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
    
    // get the assets in a collection
    static func getAssets(fromCollection collection: PHAssetCollection) -> PHFetchResult<PHAsset> {
        let photosOptions = PHFetchOptions()
        photosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        photosOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        return PHAsset.fetchAssets(in: collection, options: photosOptions)
    }
    
    static func getFamilyAlbumAssets(_ onCompletion: @escaping (PHFetchResult<PHAsset>?) -> ()) {
        let familyAlbum = self.fetchFamilyAlbumCollection()
        if let album = familyAlbum {
            let assets = getAssets(fromCollection: album)
            onCompletion(assets)
        } else {
            createAlbum(withTitle: self.albumTitle) { (album) in
                if let album = album {
                    let assets = getAssets(fromCollection: album)
                    onCompletion(assets)
                } else {
                    onCompletion(nil)
                }
            }
        }
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
    
    static func addPhotoToAlbumCollection(album: PHAssetCollection, imagePhoto: UIImage, completion: @escaping(Bool, String?) -> Void) {
        //UIImageWriteToSavedPhotosAlbum(tempImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)

        var assetPlaceholder: PHObjectPlaceholder?

        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: imagePhoto)
            assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset!
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            let enumeration: NSArray = [assetPlaceholder!]
            albumChangeRequest!.addAssets(enumeration)
        }, completionHandler: { (success, error) in
            
            if success {
                //let collection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [assetPlaceholder!.localIdentifier], options: nil)
                //self.assetCollection = collection.firstObject as! PHAssetCollection
                completion(true, assetPlaceholder!.localIdentifier)
            } else {
                completion(false, nil)
            }
        })
    }
    
    static func addPhotoToFamilyAssets(_ imagePhoto: UIImage, completion: @escaping (Bool, String?) -> Void) {
        let familyAlbum = self.fetchFamilyAlbumCollection()
        if let album = familyAlbum {
            addPhotoToAlbumCollection(album: album, imagePhoto: imagePhoto, completion: completion)
        } else {
            createAlbum(withTitle: self.albumTitle) { (album) in
                if let album = album {
                    addPhotoToAlbumCollection(album: album, imagePhoto: imagePhoto, completion: completion)
                } else {
                    completion(false, nil)
                }
            }
        }
    }
    
    static func deleteAssets(_ assets: NSArray, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges( {
            PHAssetChangeRequest.deleteAssets(assets)},
            completionHandler: { bSuccess, error in
                completion(bSuccess)
        })
    }
}

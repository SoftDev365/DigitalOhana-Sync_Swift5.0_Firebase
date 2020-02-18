//
//  LocalAlbumVC.swift
//  iPhone Family Album
//
//  Created by Admin on 11/22/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import Firebase
import FirebaseStorage
import Photos
import HelpCrunchSDK

private let reuseIdentifier = "FrameCell"

class AlbumsVC: BaseVC, UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout  {

    var albumList: PHFetchResult<PHAssetCollection>?

    @IBOutlet weak var collectionView: UICollectionView!
    //@IBOutlet weak var btnNavLeft: UIBarButtonItem!
    //@IBOutlet weak var btnNavRight: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.title = "Photo Albums"
        self.accessToPHLibrary()
    }
    
    func accessToPHLibrary() {
        let status = PHPhotoLibrary.authorizationStatus()

        if (status == PHAuthorizationStatus.authorized) {
            // Access has been granted.
            self.loadPhoneAlbums()
        }
        else if (status == PHAuthorizationStatus.denied) {
            // Access has been denied.
        }
        else if (status == PHAuthorizationStatus.notDetermined) {
            // Access has not been determined.
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                if (newStatus == PHAuthorizationStatus.authorized) {
                    self.performSelector(onMainThread: #selector(self.loadPhoneAlbums), with: nil, waitUntilDone: false)
                }
                else {

                }
            })
        }
        else if (status == PHAuthorizationStatus.restricted) {
            // Restricted access - normally won't happen.
        }
    }
    
    @objc func loadPhoneAlbums() {
        self.albumList = PHModule.fetchAllAlbums()
        self.collectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.collectionView.contentInset = UIEdgeInsets.zero
        
        // manually rotate to portrait  mode
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        //self.tabBarController?.tabBar.isHidden = false

        hideToolBar(false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.collectionView.collectionViewLayout.invalidateLayout()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (self.albumList?.count ?? 0) + 1
    }
    
    func setAlbumThumbnail(imgView:UIImageView, album: PHAssetCollection?) {
        var photos: PHFetchResult<PHAsset>!
        if album == nil {
            photos = PHModule.getAllAssets(limitCount: 1)
        } else {
            photos = PHModule.getAssets(fromCollection: album!, limitCount: 1)
        }
        
        if photos.count == 0 {
            imgView.image = UIImage(named: "noimage")
        } else {
            let asset = photos[0]
            
            //let identifier = asset.localIdentifier
            let width = imgView.bounds.width*UIScreen.main.scale
            let height = imgView.bounds.height*UIScreen.main.scale
            let size = CGSize(width:width, height:height)

            PHCachingImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil) { (image, info) in
                imgView.image = image
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)

        guard let imgView = cell.viewWithTag(1) as? UIImageView else { return cell }
        guard let label = cell.viewWithTag(2) as? UILabel else { return cell }
        guard let view_photo_area = cell.viewWithTag(3) else { return cell }

        view_photo_area.layer.cornerRadius = 10
        view_photo_area.layer.masksToBounds = true

        // recent or all
        if indexPath.row == 0 {
            let allPhotos = PHModule.getAllAssets()
            label.text = "All (\(allPhotos.count))"
            setAlbumThumbnail(imgView: imgView, album: nil)
        } else {
            let album = self.albumList!.object(at: indexPath.row-1)
            label.text = album.localizedTitle! + " (\(album.estimatedAssetCount))"
            setAlbumThumbnail(imgView: imgView, album: album)
        }
 
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.gotoAlbum(nil)
        } else {
            let album = self.albumList!.object(at: indexPath.row-1)
            self.gotoAlbum(album)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (self.view.frame.size.width - 60)/2
        
        return CGSize(width:width, height:width*1.2)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20.0
    }

    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20.0
    }

    func hideToolBar(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }

    func showToolBar(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    func gotoAlbum(_ album: PHAssetCollection?) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocalAlbum") as? LocalAlbumVC {
            vc.set(viewmode: .upload)
            vc.selectPhoneAlbum(album)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func onBtnNavLeft(_ sender: Any) {
        HelpCrunch.show(from: self) { (error) in
        }
    }
    
    // search (filter) button action
    @IBAction func onBtnNavRight(_ sender: Any) {
        
    }
}

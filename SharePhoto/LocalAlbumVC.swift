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

private let reuseIdentifier = "PhotoCell"

class LocalAlbumVC: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout  {

    var albumPhotos: PHFetchResult<PHAsset>? = nil
    let activityView = ActivityView()
    
    var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.isNavigationBarHidden = false
        //self.collectionView.automaticallyAdjustsScrollIndicatorInsets = false
        
        let buttonSize: CGFloat = 36
        let button2 = UIButton(type: .custom)
        button2.setImage(UIImage(named: "uploadphoto"), for: .normal)
        button2.addTarget(self, action: #selector(onUploadPhoto), for: .touchUpInside)
        button2.frame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
        button2.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        button2.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
        let barButton2 = UIBarButtonItem(customView: button2)
        
        //self.navigationItem.rightBarButtonItems = [barButton2, barButton1]
        self.navigationItem.rightBarButtonItems = [barButton2]

        self.fetchFamilyAlbumPhotos()
    }

    // get the assets in a collection
    func getAssets(fromCollection collection: PHAssetCollection) -> PHFetchResult<PHAsset> {
        let photosOptions = PHFetchOptions()
        photosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        photosOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        return PHAsset.fetchAssets(in: collection, options: photosOptions)
    }

    func fetchFamilyAlbumPhotos() {
        let albumTitle = "Is"
        let fetchOptions = PHFetchOptions()

        fetchOptions.predicate = NSPredicate(format: "title = %@", albumTitle)
        // get the albums list
        //let albumList = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        let albumList = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        // you can access the number of albums with
        let albumCount = albumList.count
        if albumCount <= 0 {
            return
        }

        // individual objects with
        let firstAlbum = albumList.object(at: 0)

        // get the name of the album
        // let albumTitle = firstAlbum.localizedTitle
        albumPhotos = self.getAssets(fromCollection: firstAlbum)
        
        self.collectionView.reloadData()

        /*
        albumList.enumerateObjects { (coll, _, _) in
            let result = self.getAssets(fromCollection: coll)
            print("\(coll.localizedTitle ?? "noname"): \(result.count)")

            // get an asset (eg. in a UITableView)
            let asset = result.object(at: indexPath.row)
            // get the "real" image
            PHCachingImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: nil) { (image, _) in
                // do something with the image
            }
        }*/
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.collectionView.contentInset = UIEdgeInsets.zero
        
        // manually roate to portrait  mode
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        activityView.relayoutPosition(self.view)
    }
    
    @objc func onUploadPhoto(_ sender: UIButton) {
        chooseImagePickerSource(sender)
    }

    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let photoList = self.albumPhotos else { return 0 }
        
        return photoList.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let photoList = self.albumPhotos else { return cell }
    
        let asset = photoList.object(at: indexPath.row)

        // Configure the cell
        if let label = cell.viewWithTag(2) as? UILabel {
            label.text = "title"
        }
        
        //let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        let width = UIScreen.main.scale*(self.view.frame.size.width - 5)/3
        let size = CGSize(width:width, height:width)

        PHCachingImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil) { (image, _) in
            if let imgView = cell.viewWithTag(1) as? UIImageView {
                imgView.image = image
            }
        }
        
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GalleryVC") as? GalleryVC
        {
            vc.setPhotoAlbum(self.albumPhotos!, page:indexPath.row)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (self.view.frame.size.width - 5)/3
        return CGSize(width:width, height:width)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2.0
    }

    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2.0
    }
    
    func deleteFile(_ rowIndex: Int) {
        guard let photoList = self.albumPhotos else { return }
        let asset = photoList.object(at: rowIndex)
        let arrayToDelete = NSArray(object: asset)

        PHPhotoLibrary.shared().performChanges( {
            PHAssetChangeRequest.deleteAssets(arrayToDelete)},
            completionHandler: {
                success, error in
                print("Finished deleting asset. %@", (success ? "Success" : error!))
        })
    }
    
    func deleteRow(_ rowIndex: Int) {
        var actions: [(String, UIAlertAction.Style)] = []
        actions.append(("Delete", UIAlertAction.Style.default))
        actions.append(("Cancel", UIAlertAction.Style.cancel))

        //self = ViewController
        Alerts.showActionsheet(viewController: self, title: "Warning", message: "Are you sure you delete this item?", actions: actions) { (index) in
            print("call action \(index)")

            if index == 0 {
                self.deleteFile(rowIndex)
            }
        }
    }
    
    func chooseImagePickerSource(_ sender: UIButton) {
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))

        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallary()
        }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        /*If you want work actionsheet on ipad
        then you have to use popoverPresentationController to present the actionsheet,
        otherwise app will crash on iPad */
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.bounds
            alert.popoverPresentationController?.permittedArrowDirections = .up
        default:
            break
        }

        self.present(alert, animated: true, completion: nil)
    }

    func openCamera() {
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }
        else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    func openGallary() {
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .fullScreen

        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func uploadPhoto(_ imageData: Data, fileName: String?) {
        if fileName == nil || fileName == "" {
            return
        }

        activityView.showActivityIndicator(self.view, withTitle: "Uploading...")
        let imageFileName = fileName! + ".jpg"
        GSModule.uploadFile(name: imageFileName, folderPath: "central", data: imageData) { (success) in
            self.activityView.hideActivitiIndicator()
        }
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let tempImage: UIImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        let imageData = tempImage.jpegData(compressionQuality: 1.0)

        picker.dismiss(animated: true) {
            if( imageData != nil ) {

                let alert = UIAlertController(title: "", message: "Input upload file name", preferredStyle: .alert)
                alert.addTextField { (textField) in
                    textField.text = ""
                }
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                    let textField = alert!.textFields![0]
                    self.uploadPhoto(imageData!, fileName: textField.text)
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true) {
        }
    }
}

//
//  GSAlbumVC.swift
//  SharePhoto
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

class GSAlbumVC: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout  {

    var photoList: [[String:Any]]?
    var folderPath: String?
    var fileList: [StorageItem]?
    let activityView = ActivityView()
    
    var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        self.folderPath = "central"
        
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.collectionView.contentInset = UIEdgeInsets.zero
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.photoList == nil {
            loadFileList()
        }
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        activityView.relayoutPosition(self.view)
    }
    
    @objc func onUploadPhoto(_ sender: UIButton) {
        chooseImagePickerSource(sender)
    }
    
    func loadFileList() {
        activityView.showActivityIndicator(self.view, withTitle: "Loading...")
        
        GFSModule.getAllPhotos { (success, result) in
            if !success {
                return
            }
            
            self.photoList = result
            self.collectionView.reloadData()
            self.activityView.hideActivitiIndicator()
        }
        
        /*
        GSModule.getImageFileList("central") { (fileList) in
            self.fileList = fileList
            self.collectionView.reloadData()
            
            self.activityView.hideActivitiIndicator()
        }*/
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let photoList = self.photoList else { return 0 }

        return photoList.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let photoList = self.photoList else { return cell }
    
        let photoInfo = photoList[indexPath.row]

        // Configure the cell
        //if let label = cell.viewWithTag(2) as? UILabel {
            //label.text = file.title
        //}
        
        guard let imgView = cell.viewWithTag(1) as? UIImageView else { return cell }
        guard let btnDownload = cell.viewWithTag(3) as? UIButton else { return cell }

        btnDownload.isHidden = true
        imgView.image = UIImage(named: "noimage")

        let fileID = photoInfo["id"] as! String
        GSModule.downloadImageFile(fileID: fileID, folderPath: self.folderPath!, onCompleted: { (image) in
            imgView.image = image
            if SyncModule.checkPhotoIsDownloaded(fileID: fileID) == false {
                btnDownload.isHidden = false
            }
        })
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SlideVC") as? GSGalleryVC
        {
            vc.setFileList(self.fileList!, page:indexPath.row)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (self.view.frame.size.width - 8)/3
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
        let file = self.fileList![rowIndex]
        
        activityView.showActivityIndicator(self.view, withTitle: "Deleting...")
        GSModule.deleteFile(file: file.file) { (result) in
            if result == true {
                self.fileList!.remove(at: rowIndex)
                self.collectionView.deleteItems(at: [IndexPath.init(row: rowIndex, section: 0)])
                self.activityView.hideActivitiIndicator()
            }
        }
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
        GSModule.uploadFile(name: imageFileName, folderPath: self.folderPath!, data: imageData) { (success) in
            self.activityView.hideActivitiIndicator()
            self.loadFileList()
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
    
    open func refreshFileList() {
        self.loadFileList()
    }
    
    @IBAction func onBtnDownload(_ sender: Any) {
        //guard let listPhoto = self.albumPhotos else { return }
        
        let button = sender as! UIButton
        let cell = button.superview!.superview! as! UICollectionViewCell
        let indexPath = self.collectionView.indexPath(for: cell)!

        print("----- Download Photo \(indexPath.row)-----")
        
        //let asset = listPhoto[indexPath.row]
        //uploadPhoto(asset: asset)
    }
}

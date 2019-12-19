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

class GSAlbumVC: UICollectionViewController, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout  {

    var photoList: [[String:Any]]?
    var folderPath: String?
    let activityView = ActivityView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

        refreshFileList()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        activityView.relayoutPosition(self.view)
    }
    
    @objc func onUploadPhoto(_ sender: UIButton) {

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
        GSModule.downloadImageFile(fileID: fileID, folderPath: self.folderPath!, onCompleted: { (fileID, image) in
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
            vc.setFileList(self.photoList!, page:indexPath.row)
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
        /*
        let file = self.fileList![rowIndex]
        
        activityView.showActivityIndicator(self.view, withTitle: "Deleting...")
        GSModule.deleteFile(file: file.file) { (result) in
            if result == true {
                self.fileList!.remove(at: rowIndex)
                self.collectionView.deleteItems(at: [IndexPath.init(row: rowIndex, section: 0)])
                self.activityView.hideActivitiIndicator()
            }
        }*/
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
    
    open func uploadPhoto(_ image: UIImage ) {
        activityView.showActivityIndicator(self.view, withTitle: "Uploading...")
        SyncModule.uploadPhoto(image: image) { (success) in
            self.activityView.hideActivitiIndicator()
            Global.setNeedRefresh()
            // update UI
            self.refreshFileList()
        }
    }
    
    open func refreshFileList() {
        if Global.needRefreshStorage == true {
            Global.needRefreshStorage = false
            self.loadFileList()
        }
    }
    
    func downloadImage(image: UIImage, photoInfo: [String: Any]) {
        activityView.showActivityIndicator(self.view, withTitle: "Loading...")
        SyncModule.downloadImage(photoInfo: photoInfo, image: image) { (success) in
            DispatchQueue.main.sync {
                self.activityView.hideActivitiIndicator()
                
                Global.setNeedRefresh()
                // update UI
                self.refreshFileList()
            }
        }
    }
    
    @IBAction func onBtnDownload(_ sender: Any) {
        let button = sender as! UIButton
        let cell = button.superview!.superview! as! UICollectionViewCell
        let indexPath = self.collectionView.indexPath(for: cell)!
        guard let imgView = cell.viewWithTag(1) as? UIImageView else { return }

        guard let photoList = self.photoList else { return }
        let photoInfo = photoList[indexPath.row]
        let fileID = photoInfo["id"] as! String
        
        // not downloaded yet
        if SyncModule.checkPhotoIsDownloaded(fileID: fileID) == false {
            print("----- Download Photo \(indexPath.row)-----")
            if imgView.image != nil {
                downloadImage(image: imgView.image!, photoInfo: photoInfo)
            }
        } else {
            // delete ?
            // check if photo is uploaded by me (check email or user id)
        }
    }
}

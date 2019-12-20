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

class HomeVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate  {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnNavLeft: UIBarButtonItem!
    @IBOutlet weak var btnNavRight: UIBarButtonItem!
    @IBOutlet weak var btnAdd: UIButton!

    var bEditMode: Bool = false
    var photoList: [[String:Any]]?
    var folderPath: String?
    let activityView = ActivityView()
    
    var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bEditMode = false
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.folderPath = "central"
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.isNavigationBarHidden = false
        //self.collectionView.automaticallyAdjustsScrollIndicatorInsets = false
        
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: attributes)
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        refreshControl.tintColor = .white
        
        self.collectionView.addSubview(refreshControl) // not required when using UITableViewController
        
        let lpgr : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        lpgr.minimumPressDuration = 0.5
        lpgr.delegate = self
        lpgr.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(lpgr)
        
        /*
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
        */
    }

    @objc func refresh(_ sender: Any) {
       // Code to refresh table view
        loadFileList()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.collectionView.contentInset = UIEdgeInsets.zero
        self.tabBarController?.tabBar.isHidden = false
        
        // manually roate to portrait  mode
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        
        //self.navigationController?.setToolbarHidden(true, animated: true)
        //switchModeTo(editMode:false)
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
        GFSModule.getAllPhotos { (success, result) in
            self.refreshControl.endRefreshing()
            self.activityView.hideActivitiIndicator()
            
            if !success {
                return
            }
            
            self.photoList = result
            self.collectionView.reloadData()
        }
        
        /*
        GSModule.getImageFileList("central") { (fileList) in
            self.fileList = fileList
            self.collectionView.reloadData()
            
            self.activityView.hideActivitiIndicator()
        }*/
    }

    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let photoList = self.photoList else { return 0 }

        //return photoList.count
        return 20
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCell

        cell.setEmpty()
        cell.setSelectable(false)
        //cell.setCheckboxStatus(self.bEditMode, checked: false)

        guard let photoList = self.photoList else { return cell }
        if indexPath.row >= photoList.count {
            return cell
        }
        
        let photoInfo = photoList[indexPath.row]
        let fileID = photoInfo["id"] as! String
        
        cell.setCloudFile(fileID)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.bEditMode == true {
            let cell = self.collectionView.cellForItem(at: indexPath) as! PhotoCell
            cell.reverseCheckStatus()
        } else if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SlideVC") as? GSGalleryVC
        {
            //self.tabBarController?.tabBar.isHidden = true//bIsFullscreen
            self.navigationController?.setToolbarHidden(true, animated: false)
            hideTabBar()
            
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
            activityView.showActivityIndicator(self.view, withTitle: "Loading...")
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
    
    func switchModeTo(editMode:Bool) {
        self.bEditMode = editMode

        if editMode == true {
            btnNavLeft.image = nil
            btnNavLeft.title = "Cancel"
            btnAdd.isHidden = true
            hideTabBar()
        } else {
            btnNavLeft.image = UIImage(named:"icon_alarm")
            btnNavLeft.title = ""
            btnAdd.isHidden = false
            showTabBar()
        }

        let indexs = self.collectionView.indexPathsForVisibleItems
        for indexPath in indexs {
            let cell = self.collectionView.cellForItem(at: indexPath) as! PhotoCell
            cell.setCheckboxStatus(editMode, checked: false)
        }
        //self.collectionView.reloadData()
    }
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        if gesture.state != .began {
            return
        }

        let p = gesture.location(in: self.collectionView)

        if let indexPath = self.collectionView.indexPathForItem(at: p) {
            switchModeTo(editMode:true)
            let cell = self.collectionView.cellForItem(at: indexPath) as! PhotoCell
            cell.setCheckboxStatus(true, checked: true)
        } else {
            print("couldn't find index path")
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
    
    @IBAction func onBtnNavLeft(_ sender: Any) {
        switchModeTo(editMode:false)
    }
    
    @IBAction func onBtnNavRight(_ sender: Any) {
        
    }
    
    @IBAction func onBtAdd(_ sender: Any) {
        
    }
    
    func hideTabBar() {
        var fram = self.tabBarController!.tabBar.frame
        fram.origin.y = self.view.frame.size.height
        
        UIView.animate(withDuration: 0.2, animations: {
            self.tabBarController?.tabBar.frame = fram
        }) { (success) in
            //self.tabBarController?.tabBar.isHidden = true
            self.navigationController?.setToolbarHidden(false, animated: false)
        }
    }

    func showTabBar() {
        var fram = self.tabBarController!.tabBar.frame
        fram.origin.y = self.view.frame.size.height - (fram.size.height)
        
        self.tabBarController?.tabBar.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            self.tabBarController?.tabBar.frame = fram
        }) { (success) in
            self.navigationController?.setToolbarHidden(true, animated: false)
        }
    }
}

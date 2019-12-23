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

class LocalAlbumVC: UICollectionViewController, UICollectionViewDelegateFlowLayout  {

    enum ViewMode: Int {
       case local = 0
       case upload = 1
       case download = 2
    }
    
    var viewMode: ViewMode = .local    
    var bEditMode: Bool = false
    var albumPhotos: PHFetchResult<PHAsset>? = nil
    
    var selectedPhotoList: [PHAsset]?
    var backupSelection: [Int] = []
    
    @IBOutlet weak var btnNavRight: UIBarButtonItem!
    @IBOutlet weak var btnToolSelectAll: UIBarButtonItem!
    
    let activityView = ActivityView()
    let refreshControl = UIRefreshControl()
    
    open func setView(mode: ViewMode) {
        self.viewMode = mode
        
        if self.viewMode == .upload {
            prepareNewSelecting()
            self.bEditMode = true
            self.hidesBottomBarWhenPushed = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        //self.navigationController?.isNavigationBarHidden = false
        self.accessToPHLibrary()
        
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: attributes)
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        refreshControl.tintColor = .white
        
        self.collectionView.addSubview(refreshControl) // not required when using UITableViewController
    }
    
    @objc func refresh(_ sender: Any) {
        fetchFamilyAlbumPhotos()
    }
    
    func accessToPHLibrary() {
        let status = PHPhotoLibrary.authorizationStatus()

        if (status == PHAuthorizationStatus.authorized) {
            // Access has been granted.
            self.fetchFamilyAlbumPhotos()
        }
        else if (status == PHAuthorizationStatus.denied) {
            // Access has been denied.
        }
        else if (status == PHAuthorizationStatus.notDetermined) {
            // Access has not been determined.
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                if (newStatus == PHAuthorizationStatus.authorized) {
                    self.performSelector(onMainThread: #selector(self.fetchFamilyAlbumPhotos), with: nil, waitUntilDone: false)
                }
                else {

                }
            })
        }
        else if (status == PHAuthorizationStatus.restricted) {
            // Restricted access - normally won't happen.
        }
    }
    
    @objc func fetchFamilyAlbumPhotos() {
        PHModule.getFamilyAlbumAssets { (result) in
            self.refreshControl.endRefreshing()

            guard let photoList = result else { return }
            self.albumPhotos = photoList
            
            var fileNames: [String] = []
            for index in 0..<photoList.count {
                let asset = photoList[index]
                fileNames += [asset.localIdentifier]
            }
            
            SqliteManager.syncFileInfos(arrFiles: fileNames)

            DispatchQueue.main.async() {
                self.collectionView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.collectionView.contentInset = UIEdgeInsets.zero
        
        // manually roate to portrait  mode
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        //self.tabBarController?.tabBar.isHidden = false
        
        if self.bEditMode {
            showToolBar(false)
        } else {
            showTabBar()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.collectionView.collectionViewLayout.invalidateLayout()
        refreshAlbum()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityView.relayoutPosition(self.view)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let photoList = self.albumPhotos else { return 0 }
        
        return photoList.count
    }

    func isSelectedBefore(_ indexPath: IndexPath) -> Bool {
        for row in self.backupSelection {
            if row == indexPath.row {
                return true
            }
        }
        
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCell
        guard let photoList = self.albumPhotos else { return cell }
    
        let asset = photoList.object(at: indexPath.row)

        //let width = UIScreen.main.scale*(self.view.frame.size.width - 4)/3
        let width = UIScreen.main.scale*cell.frame.size.width
        cell.setLocalAsset(asset, width: width)
        
        if self.bEditMode == false {
            cell.setSelectable(false)
        } else {
            
            cell.setPreviousStatus(isSelectedBefore(indexPath))
            
            if isSelectedPhoto(asset) {
                cell.setCheckboxStatus(self.bEditMode, checked: true)
            } else {
                cell.setCheckboxStatus(self.bEditMode, checked: false)
            }
        }
 
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.bEditMode == true {
            selectOrDeselectCell(indexPath, refreshCell: true)
        } else if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GalleryVC") as? LocalGalleryVC {
            hideTabBar()
            vc.setPhotoAlbum(self.albumPhotos!, page:indexPath.row)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (self.view.frame.size.width - 4)/3
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
        
        PHModule.deleteAssets(arrayToDelete) { (bSuccess) in
            print("Finished deleting asset. %@", (bSuccess ? "Success" : "Fail to Delete"))
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
    
    func uploadPhoto(asset: PHAsset) {
        activityView.showActivityIndicator(self.view, withTitle: "Uploading...")        
        SyncModule.uploadPhoto(asset: asset) { (success) in
            self.activityView.hideActivitiIndicator()
            
            Global.setNeedRefresh()
            // update UI
            self.refreshAlbum()
        }
    }
    
    func addPhotoToLocalAlbum(_ imagePhoto: UIImage) {
        PHModule.addPhotoToFamilyAssets(imagePhoto) { (bSuccess, _) in
            DispatchQueue.main.sync {
                // update UI
                self.fetchFamilyAlbumPhotos()
            }
        }
    }
    
    func refreshAlbum() {
        if Global.needRefreshLocal == true {
            Global.needRefreshLocal = false
            self.fetchFamilyAlbumPhotos()
        }
    }
    
    func hideToolBar(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }

    func showToolBar(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    func hideTabBar() {
        var fram = self.tabBarController!.tabBar.frame
        fram.origin.y = self.view.frame.size.height
        
        UIView.animate(withDuration: 0.2, animations: {
            self.tabBarController?.tabBar.frame = fram
        }) { (success) in
            self.tabBarController?.tabBar.isHidden = true
            //self.navigationController?.setToolbarHidden(false, animated: false)
        }
    }

    func showTabBar() {
        var fram = self.tabBarController!.tabBar.frame
        
        if self.view.frame.size.width > self.view.frame.size.height {
            fram.origin.y = self.view.frame.size.width - (fram.size.height)
        } else {
            fram.origin.y = self.view.frame.size.height - (fram.size.height)
        }
        
        self.tabBarController?.tabBar.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            self.tabBarController?.tabBar.frame = fram
        }) { (success) in
        }
    }
    
    func prepareNewSelecting() {
        self.selectedPhotoList = [PHAsset]()
    }
    
    func isSelectedPhoto(_ asset: PHAsset) -> Bool {
        let assetID = asset.localIdentifier
        guard let photoList = self.selectedPhotoList else { return false }
        
        for item in photoList {
            if item.localIdentifier == assetID {
                return true
            }
        }
        
        return false
    }
    
    func addPhotoToSelectedList(_ asset: PHAsset) {
        if self.selectedPhotoList == nil {
            return
        }
        
        self.selectedPhotoList! += [asset]
    }
    
    func removePhotoFromSelectedList(_ asset: PHAsset) {
        guard let photoList = self.selectedPhotoList else { return }
        
        let assetID = asset.localIdentifier
        self.selectedPhotoList = photoList.filter { $0.localIdentifier != assetID }
    }
    
    func isAllSelected() -> Bool {
        guard let photoList = self.albumPhotos else { return false }
       
        for i in 0 ..< photoList.count {
            let asset = photoList.object(at: i)
            if isSelectedPhoto(asset) == false {
                return false
            }
        }
       
        return true
   }
    
    func selectOrDeselectCell(_ indexPath: IndexPath, refreshCell: Bool) {
        guard let photoList = self.albumPhotos else { return }
        
        let asset = photoList.object(at: indexPath.row)
        let cell = self.collectionView.cellForItem(at: indexPath) as! PhotoCell
        
        if isSelectedPhoto(asset) == false {
            addPhotoToSelectedList(asset)
            if refreshCell {
                cell.setCheckboxStatus(true, checked: true)
                if isAllSelected() {
                    btnToolSelectAll.title = "Deselect All"
                }
            }
        } else {
            removePhotoFromSelectedList(asset)
            if refreshCell {
                cell.setCheckboxStatus(true, checked: false)
                btnToolSelectAll.title = "Select All"
            }
        }
    }
    
    func clearBackupSelection() {
        self.backupSelection = []
    }

    func backupCurrentSelection() {
        let items = self.collectionView.indexPathsForVisibleItems
        
        self.backupSelection = []
        for indexPath in items {
            let cell = self.collectionView.cellForItem(at: indexPath) as! PhotoCell
            if cell.isChecked() {
                self.backupSelection += [indexPath.row]
            }
        }
    }
    
    func selectAll() {
        guard let photoList = self.albumPhotos else { return }
        
        for i in 0 ..< photoList.count {
            let asset = photoList.object(at: i)
            if isSelectedPhoto(asset) == false {
                addPhotoToSelectedList(asset)
            }
        }

        backupCurrentSelection()
        self.collectionView.reloadData()
        self.collectionView.performBatchUpdates(nil, completion: { (result) in
            self.clearBackupSelection()
        })
    }
    
    func deselectAll() {
        self.selectedPhotoList = []

        backupCurrentSelection()
        self.collectionView.reloadData()
        self.collectionView.performBatchUpdates(nil, completion: { (result) in
            self.clearBackupSelection()
        })
    }
    
    func switchModeTo(editMode:Bool) {
        self.bEditMode = editMode

        if editMode == true {
            //btnNavLeft.image = nil
            //btnNavLeft.title = "Cancel"
            showToolBar(true)
        } else {
            //btnNavLeft.image = UIImage(named:"icon_alarm")
            //btnNavLeft.title = ""
            hideToolBar(true)
            
            Global.needDoneSelectionAtHome = false
        }

        self.collectionView.reloadData()
    }
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        if gesture.state != .began {
            return
        }

        let p = gesture.location(in: self.collectionView)

        if let indexPath = self.collectionView.indexPathForItem(at: p) {
            prepareNewSelecting()
            selectOrDeselectCell(indexPath, refreshCell: false)
            switchModeTo(editMode:true)
        } else {
            print("couldn't find index path")
        }
    }
    
    // alarm button action
    @IBAction func onBtnNavLeft(_ sender: Any) {
        switchModeTo(editMode:false)
    }
    
    // search (filter) button action
    @IBAction func onBtnNavRight(_ sender: Any) {
        
    }
    
    // selected from each photo cell
    @IBAction func onBtnUploadPhoto(_ sender: Any) {
        guard let listPhoto = self.albumPhotos else { return }
        
        let button = sender as! UIButton
        let cell = button.superview!.superview! as! UICollectionViewCell
        let indexPath = self.collectionView.indexPath(for: cell)!
        
        print("----- UploadPhoto \(indexPath.row)-----")
        
        let asset = listPhoto[indexPath.row]
        uploadPhoto(asset: asset)
    }
    
    @IBAction func onBtnSelectAll(_ sender: Any) {
        if btnToolSelectAll.title == "Select All" {
            btnToolSelectAll.title = "Deselect All"
            selectAll()
        } else {
            btnToolSelectAll.title = "Select All"
            deselectAll()
        }
    }
    
    func alertNoSelection() {
        let alert = UIAlertController(title: "You should select photos first.", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    func uploadPhoto1(asset: PHAsset) {
        activityView.showActivityIndicator(self.view, withTitle: "Uploading...")
        SyncModule.uploadPhoto(asset: asset) { (success) in
            self.activityView.hideActivitiIndicator()
            
            Global.setNeedRefresh()
            // update UI
            self.refreshAlbum()
        }
    }
    
    func uploadSelectedPhotos() {
        self.activityView.showActivityIndicator(self.view, withTitle: "Uploading...")
        SyncModule.downloadSelectedPhotosToLocal { (success) in
            self.activityView.hideActivitiIndicator()
            if success {
                Global.needRefreshStorage = true
            }
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func onBtnDone(_ sender: Any) {
        if self.selectedPhotoList?.count == 0 {
            alertNoSelection()
            return
        }
        
        let alert = UIAlertController(title: "Are you sure you upload selected photos?", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            self.uploadSelectedPhotos()
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

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
       case show = 0
       case upload = 1
       case download = 2
    }
    
    enum SourceType: Int {
        case local = 0
        case drive = 1
        case raspberrypi = 2
    }

    var viewMode: ViewMode = .show
    var sourceType: SourceType = .local
    var bEditMode: Bool = false
    
    var albumPhotos: [PHAsset]?
    var drivePhotos: [GTLRDrive_File]?
    
    var selectedAlbumPhotos: [PHAsset]?
    var selectedDrivePhotos: [GTLRDrive_File]?
    var backupSelection: [Int] = []
    
    @IBOutlet weak var navItem: UINavigationItem!
    //@IBOutlet weak var btnNavRight: UIBarButtonItem!
    @IBOutlet weak var btnToolSelectAll: UIBarButtonItem!
    
    let activityView = ActivityView()
    let refreshControl = UIRefreshControl()
    
    open func set(viewmode: ViewMode) {
        self.viewMode = viewmode
        
        if self.viewMode == .upload {
            prepareNewSelecting()
            self.bEditMode = true
            self.hidesBottomBarWhenPushed = true
        }
    }
    
    open func set(sourceType: SourceType) {
        self.sourceType = sourceType
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        //self.navigationController?.isNavigationBarHidden = false
        
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: attributes)
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        refreshControl.tintColor = .white
        
        self.collectionView.addSubview(refreshControl) // not required when using UITableViewController
        
        if self.sourceType == .local {
            self.navItem.title = "Local"
            self.accessToPHLibrary()
        } else if self.sourceType == .drive {
            self.navItem.title = "Drive"
            self.loadDriveFileList()
        } else if self.sourceType == .raspberrypi {
            
        }
    }
    
    @objc func refresh(_ sender: Any) {
        if self.sourceType == .local {
            self.fetchFamilyAlbumPhotos()
        } else if self.sourceType == .drive {
            self.loadDriveFileList()
        } else if self.sourceType == .raspberrypi {
            
        }
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
            guard let photoList = result else {
                DispatchQueue.main.async() {
                    self.refreshControl.endRefreshing()
                }
                return
            }
            
            self.albumPhotos = []
            
            var fileNames: [String] = []
            for index in 0 ..< photoList.count {
                let asset = photoList[index]
                
                if self.viewMode == .show {
                    self.albumPhotos! += [asset]
                } else if self.viewMode == .upload {
                    if SyncModule.checkPhotoIsUploaded(localIdentifier: asset.localIdentifier) == false {
                        self.albumPhotos! += [asset]
                    }
                }

                fileNames += [asset.localIdentifier]
            }
            
            SqliteManager.syncFileInfos(arrFiles: fileNames)

            DispatchQueue.main.async() {
                self.refreshControl.endRefreshing()
                self.collectionView.reloadData()
            }
        }
    }
    
    func filterUploadedDriveFiles(files: [GTLRDrive_File]?) {
        self.drivePhotos = []

        if let files = files {
            for file in files {
                if SyncModule.checkPhotoIsUploaded(driveFile: file) == false {
                    self.drivePhotos! += [file]
                }
            }
        }
    }
    
    func loadDriveFileList() {
        self.refreshControl.endRefreshing()
        activityView.showActivityIndicator(self.view, withTitle: "Loading...")

        GDModule.listFiles() { (fileList) in
            self.drivePhotos = []
            
            if fileList != nil {
                if self.viewMode == .show {
                    self.drivePhotos = fileList!.files
                } else if self.viewMode == .download {
                    self.drivePhotos = fileList!.files
                } else if self.viewMode == .upload {
                    self.filterUploadedDriveFiles(files: fileList!.files)
                }
            }
            
            self.collectionView.reloadData()
            self.activityView.hideActivitiIndicator()
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
        if self.sourceType == .local {
            return self.albumPhotos?.count ?? 0
        } else if self.sourceType == .drive {
            return self.drivePhotos?.count ?? 0
        } else {
            return 0
        }
    }

    func isSelectedBefore(_ indexPath: IndexPath) -> Bool {
        for row in self.backupSelection {
            if row == indexPath.row {
                return true
            }
        }
        
        return false
    }
    
    func getLocalCell(_ cell: PhotoCell, indexPath: IndexPath) -> UICollectionViewCell {
        guard let photoList = self.albumPhotos else { return cell }

        let asset = photoList[indexPath.row]

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
    
    func getDriveCell(_ cell: PhotoCell, indexPath: IndexPath) -> UICollectionViewCell {
        guard let photoList = self.drivePhotos else { return cell }

        let file = photoList[indexPath.row]
        cell.setDriveFile(file)

        if self.bEditMode == false {
           cell.setSelectable(false)
        } else {
           
           cell.setPreviousStatus(isSelectedBefore(indexPath))

           if isSelectedPhoto(file) {
               cell.setCheckboxStatus(self.bEditMode, checked: true)
           } else {
               cell.setCheckboxStatus(self.bEditMode, checked: false)
           }
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCell
        
        if self.sourceType == .local {
            return getLocalCell(cell, indexPath: indexPath)
        } else if self.sourceType == .drive {
            return getDriveCell(cell, indexPath: indexPath)
        } else {
            return cell
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.bEditMode == true {
            selectOrDeselectCell(indexPath, refreshCell: true)
        } else if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GalleryVC") as? LocalGalleryVC {
            hideTabBar()
            if self.sourceType == .local {
                vc.setAlbumPhotos(self.albumPhotos!, page: indexPath.row)
            } else if self.sourceType == .drive {
                vc.setDrivePhotos(self.drivePhotos!, page: indexPath.row)
            }

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
        let asset = photoList[rowIndex]
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
            self.refresh(self)
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
        self.selectedAlbumPhotos = [PHAsset]()
        self.selectedDrivePhotos = [GTLRDrive_File]()
    }
    
    func isSelectedPhoto(_ asset: PHAsset) -> Bool {
        let assetID = asset.localIdentifier
        guard let photoList = self.selectedAlbumPhotos else { return false }
        
        for item in photoList {
            if item.localIdentifier == assetID {
                return true
            }
        }
        
        return false
    }
    
    func isSelectedPhoto(_ file: GTLRDrive_File) -> Bool {
        let fileID = file.identifier
        guard let photoList = self.selectedDrivePhotos else { return false }
        
        for file in photoList {
            if file.identifier == fileID {
                return true
            }
        }

        return false
    }

    func isSelectedPhoto(_ row: Int) -> Bool {
        if self.sourceType == .local {
            guard let photoList = self.albumPhotos else { return false }
            return isSelectedPhoto(photoList[row])
        } else if self.sourceType == .drive {
            guard let photoList = self.drivePhotos else { return false }
            return isSelectedPhoto(photoList[row])
        } else {
            return false
        }
    }
    
    func addPhotoToSelectedList(_ row: Int) {
        if self.sourceType == .local {
            guard let photoList = self.albumPhotos else { return }
            self.selectedAlbumPhotos! += [photoList[row]]
        } else if self.sourceType == .drive {
            guard let photoList = self.drivePhotos else { return }
            self.selectedDrivePhotos! += [photoList[row]]
        } else {

        }
    }
    
    func removePhotoFromSelectedList(_ asset: PHAsset) {
        guard let photoList = self.selectedAlbumPhotos else { return }

        let assetID = asset.localIdentifier
        self.selectedAlbumPhotos = photoList.filter { $0.localIdentifier != assetID }
    }
    
    func removePhotoFromSelectedList(_ file: GTLRDrive_File) {
        guard let photoList = self.selectedDrivePhotos else { return }

        let fileID = file.identifier
        self.selectedDrivePhotos = photoList.filter { $0.identifier != fileID }
    }
    
    func removePhotoFromSelectedList(_ row: Int) {
        if self.sourceType == .local {
            guard let photoList = self.albumPhotos else { return }
            removePhotoFromSelectedList(photoList[row])
        } else if self.sourceType == .drive {
            guard let photoList = self.drivePhotos else { return }
            removePhotoFromSelectedList(photoList[row])
        } else {

        }
    }
    
    func isAllLocalFilesSelected() -> Bool {
        guard let photoList = self.albumPhotos else { return false }
        
        for i in 0 ..< photoList.count {
            let asset = photoList[i]
            if isSelectedPhoto(asset) == false {
                return false
            }
        }
    
        return true
    }
    
    func isAllDriveFilesSelected() -> Bool {
        guard let photoList = self.drivePhotos else { return false }
        
        for i in 0 ..< photoList.count {
            let asset = photoList[i]
            if isSelectedPhoto(asset) == false {
                return false
            }
        }
    
        return true
    }

    func isAllSelected() -> Bool {
        if self.sourceType == .local {
            return isAllLocalFilesSelected()
        } else if self.sourceType == .drive {
            return isAllDriveFilesSelected()
        } else {
            return false
        }
   }
    
    func selectOrDeselectCell(_ indexPath: IndexPath, refreshCell: Bool) {

        let cell = self.collectionView.cellForItem(at: indexPath) as! PhotoCell
        
        if isSelectedPhoto(indexPath.row) == false {
            addPhotoToSelectedList(indexPath.row)
            if refreshCell {
                cell.setCheckboxStatus(true, checked: true)
                if isAllSelected() {
                    btnToolSelectAll.title = "Deselect All"
                }
            }
        } else {
            removePhotoFromSelectedList(indexPath.row)
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
        let nCount = self.collectionView(self.collectionView, numberOfItemsInSection: 0)
        
        for i in 0 ..< nCount {
            if isSelectedPhoto(i) == false {
                addPhotoToSelectedList(i)
            }
        }

        backupCurrentSelection()
        self.collectionView.reloadData()
        self.collectionView.performBatchUpdates(nil, completion: { (result) in
            self.clearBackupSelection()
        })
    }
    
    func deselectAll() {
        self.selectedAlbumPhotos = []
        self.selectedDrivePhotos = []

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
    
    func alertUploadResult(nUpload:Int, nSkip: Int, nFail: Int) {
        let strMsg = Global.getProcessResultMsg(titles: ["Uploaded", "Skipped", "Failed"], counts: [nUpload, nSkip, nFail])
        let alert = UIAlertController(title: strMsg, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            if nUpload > 0 {
                //self.navigationController?.popViewController(animated: true)
                //self.hideToolBar(false)
                //self.navigationController?.popToRootViewController(animated: true)
                self.prepareNewSelecting()
                self.refreshAlbum()
            }
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    func onUploadDone(nUpload:Int, nSkip: Int, nFail: Int) {
        if nUpload > 0 {
            Global.setNeedRefresh()
            
            GFSModule.getAllPhotos { (success, photoList) in
                DispatchQueue.main.async() {
                    self.activityView.hideActivitiIndicator()
                    self.alertUploadResult(nUpload: nUpload, nSkip: nSkip, nFail: nFail)
                }                
            }
        } else {
            self.activityView.hideActivitiIndicator()
            alertUploadResult(nUpload: nUpload, nSkip: nSkip, nFail: nFail)
        }
    }

    func uploadSelectedPhotos() {
        self.activityView.showActivityIndicator(self.view, withTitle: "Uploading...")

        if self.sourceType == .local {
            SyncModule.uploadSelectedLocalPhotos(assets: self.selectedAlbumPhotos!) { (nUpload, nSkip, nFail) in
                self.onUploadDone(nUpload: nUpload, nSkip: nSkip, nFail: nFail)
            }
        } else {
            SyncModule.uploadSelectedDrivePhotos(files: self.selectedDrivePhotos!) { (nUpload, nSkip, nFail) in
                self.onUploadDone(nUpload: nUpload, nSkip: nSkip, nFail: nFail)
            }
        }
    }
    
    func getSelectedCount() -> Int {
        if self.sourceType == .local {
            return self.selectedAlbumPhotos?.count ?? 0
        } else if self.sourceType == .drive {
            return self.selectedDrivePhotos?.count ?? 0
        }
        
        return 0
    }
    
    @IBAction func onBtnDone(_ sender: Any) {
        if self.getSelectedCount() == 0 {
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

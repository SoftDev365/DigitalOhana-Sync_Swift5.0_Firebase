//
//  HomeVC.swift
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
import HelpCrunchSDK

private let reuseIdentifier = "PhotoCell"

class HomeVC: BaseVC, UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, SearchFieldVCDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnNavLeft: UIBarButtonItem!
    @IBOutlet weak var btnNavRight: UIBarButtonItem!
    
    @IBOutlet weak var btnToolSelectAll: UIBarButtonItem!
    @IBOutlet weak var btnToolDelete: UIBarButtonItem!
    @IBOutlet weak var btnToolDownload: UIBarButtonItem!

    @IBOutlet weak var btnAdd: UIButton!

    var bEditMode: Bool = false
    var folderPath: String = "central"
    var photoList: [FSPhotoInfo]?
    var selectedPhotoList: [FSPhotoInfo]?
    var backupSelection: [Int] = []
    
    var bSynchronizeDrive: Bool = false
    var albumPhotos: [PHAsset] = []
    var drivePhotos: [GTLRDrive_File] = []

    let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bEditMode = false
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        //self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.isNavigationBarHidden = false
        
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: attributes)
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        refreshControl.tintColor = .white
        
        self.collectionView.addSubview(refreshControl) // not required when using UITableViewController
        
        let lpgr : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        lpgr.minimumPressDuration = 0.5
        lpgr.delegate = self
        lpgr.delaysTouchesBegan = true
        self.collectionView.addGestureRecognizer(lpgr)
        
        self.btnAdd.layer.borderWidth = 0.5
        self.btnAdd.layer.borderColor = UIColor(white: 0.3, alpha: 1.0).cgColor
        
        switchModeTo(editMode:false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(numberOfUnreadMessagesChanged), name: NSNotification.Name.HCSUnreadMessages, object: nil)
    }

    @objc func refresh(_ sender: Any) {
        loadFileList()
    }
    
    @objc func numberOfUnreadMessagesChanged() {
        if self.bEditMode == true {
            return
        }

        let messages = Int(HelpCrunch.numberOfUnreadMessages())
        btnNavLeft.addBadge(number: messages)
        if messages > 0 {
            btnNavLeft.addBadge(number: messages)
        } else {
            btnNavLeft.removeBadge()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.collectionView.contentInset = UIEdgeInsets.zero
        self.tabBarController?.tabBar.isHidden = false
        
        // manually roate to portrait  mode
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        
        // when download completed
        if Global.needDoneSelectionAtHome {
            switchModeTo(editMode: false)
        }

        showTabBar()
        if self.bEditMode {
            showToolBar(false)
        }
        
        if self.bSynchronizeDrive {
            self.bSynchronizeDrive = false
            self.loadDriveFileList()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        refreshFileList()
        self.collectionView.collectionViewLayout.invalidateLayout()
        
        self.numberOfUnreadMessagesChanged()
    }
    
    func loadFileList() {
        //GFSModule.getAllPhotos { (success, result) in
        GFSModule.searchPhotosBy(withDeleted: false, options: Global.searchOption) { (success, result) in
            self.refreshControl.endRefreshing()
            self.hideBusyDialog()
            
            if !success {
                return
            }
            
            self.photoList = result
            self.collectionView.reloadData()
            
            if Global.bNeedToSynchronize {
                self.checkAndAutoUpload()
            }
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

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCell

        guard let photoList = self.photoList else { return cell }
        let row = indexPath.row

        let photoInfo = photoList[row]
        let fileID = photoInfo.id

        cell.setCloudFile(fileID)
        
        if self.bEditMode == false {
            cell.setSelectable(false)
        } else {
            
            cell.setPreviousStatus(isSelectedBefore(indexPath))
            
            if isSelectedPhoto(photoInfo) {
                cell.setCheckboxStatus(self.bEditMode, checked: true)
            } else {
                cell.setCheckboxStatus(self.bEditMode, checked: false)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.bEditMode == true {
            selectOrDeselectCell(indexPath, refreshCell: true)
        } else if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SlideVC") as? GSGalleryVC {
            hideTabBar()
            
            vc.setFileList(self.photoList!, page:indexPath.row)
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

    open func refreshFileList() {
        if Global.needRefreshStorage == true {
            Global.needRefreshStorage = false
            self.showBusyDialog("Loading...")
            self.loadFileList()
        }
    }
    
    open func setAddButtonLayout(_ size: CGFloat) {
        for constraint in self.view.constraints {
            if constraint.identifier == "add_tool_gap" {
               constraint.constant = size
            }
        }

        self.view.layoutIfNeeded()
    }
    
    func switchModeTo(editMode:Bool) {
        self.bEditMode = editMode

        if editMode == true {
            btnNavLeft.image = nil
            btnNavLeft.title = "Cancel"
            btnAdd.isHidden = true
            showToolBar(true)
            self.setAddButtonLayout(-50)
            
            btnNavLeft.removeBadge()
        } else {
            btnNavLeft.image = UIImage(systemName: "questionmark.circle")
            btnNavLeft.title = ""
            btnAdd.isHidden = false
            hideToolBar(true)
            self.setAddButtonLayout(0)
            Global.needDoneSelectionAtHome = false
            
            self.perform(#selector(numberOfUnreadMessagesChanged), with: nil, afterDelay: 0.01)
        }

        self.collectionView.reloadData()
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
        self.selectedPhotoList = [FSPhotoInfo]()
    }
    
    func isSelectedPhoto(_ photoInfo:FSPhotoInfo) -> Bool {
        let photoID = photoInfo.id
        guard let photoList = self.selectedPhotoList else { return false }
        
        for item in photoList {
            if item.id == photoID {
                return true
            }
        }
        
        return false
    }
    
    func addPhotoToSelectedList(_ photoInfo:FSPhotoInfo) {
        if self.selectedPhotoList == nil {
            return
        }
        
        self.selectedPhotoList! += [photoInfo]
    }
    
    func removePhotoFromSelectedList(_ photoInfo:FSPhotoInfo) {
        guard let photoList = self.selectedPhotoList else { return }
        
        let photoID = photoInfo.id
        self.selectedPhotoList = photoList.filter { $0.id != photoID }
    }
    
    func isAllSelected() -> Bool {
        guard let photoList = self.photoList else { return false }

        for photoInfo in photoList {
            if isSelectedPhoto(photoInfo) == false {
                return false
            }
        }
        
        return true
    }
    
    func selectOrDeselectCell(_ indexPath: IndexPath, refreshCell:Bool) {
        guard let photoList = self.photoList else { return }
        
        let photoInfo = photoList[indexPath.row]
        let cell = self.collectionView.cellForItem(at: indexPath) as! PhotoCell
        
        if isSelectedPhoto(photoInfo) == false {
            addPhotoToSelectedList(photoInfo)
            if refreshCell {
                cell.setCheckboxStatus(true, checked: true)
                if isAllSelected() {
                    btnToolSelectAll.title = "Deselect All"
                }
            }
        } else {
            removePhotoFromSelectedList(photoInfo)
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
        guard let photoList = self.photoList else { return }
        
        for photoInfo in photoList {
            if isSelectedPhoto(photoInfo) == false {
                addPhotoToSelectedList(photoInfo)
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
        if self.bEditMode == true {
            switchModeTo(editMode:false)
        } else {
            HelpCrunch.show(from: self) { (error) in
            }
        }
    }
    
    // search (filter) button action
    @IBAction func onBtnNavRight(_ sender: Any) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchFieldVC") as? SearchFieldVC {
            hideTabBar()
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func onBtAdd(_ sender: Any) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocationVC") as? LocationVC {
            hideTabBar()

            vc.setView(mode: .upload)
            navigationController?.pushViewController(vc, animated: true)
        }
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
    
    func deleteSelectedPhotos() {
        if self.selectedPhotoList == nil {
            return
        }

        self.showBusyDialog("Deleting...")
        SyncModule.deleteSelectedPhotosFromCloud(photoInfos: self.selectedPhotoList!) { (nDeleted, nSkipped, nFailed) in
            self.hideBusyDialog()
            if nDeleted > 0 {
                Global.setNeedRefresh()
            }

            let strMsg = Global.getProcessResultMsg(titles: ["Deleted", "Not allowed", "Failed"], counts: [nDeleted, nSkipped, nFailed])
            let alert = UIAlertController(title: strMsg, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                self.switchModeTo(editMode: false)
                //self.prepareNewSelecting()
                self.refreshFileList()
            }))

            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func onBtnDelete(_ sender: Any) {
        if self.selectedPhotoList?.count == 0 {
            alertNoSelection()
            return
        }

        var actions: [(String, UIAlertAction.Style)] = []
        actions.append(("Yes", UIAlertAction.Style.default))
        actions.append(("Cancel", UIAlertAction.Style.cancel))

        Alerts.showActionsheet(viewController: self, title: "Delete the selected photos?", message: "", actions: actions) { (index) in
            if index == 0 {
                self.deleteSelectedPhotos();
            }
        }
    }
    
    @IBAction func onBtnDownload(_ sender: Any) {
        if self.selectedPhotoList?.count == 0 {
            alertNoSelection()
            return
        }

        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocationVC") as? LocationVC {
            hideTabBar()
            hideToolBar(false)
            
            Global.selectedCloudPhotos = self.selectedPhotoList
            vc.setView(mode: .download)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func didClickOnSearchButton() {
        Global.needRefreshStorage = true
        refreshFileList()
    }
    
    //===============================================================================================//
    func alertLocalUploadResult(nUpload:Int, nSkip: Int, nFail: Int) {
        let strMsg = Global.getProcessResultMsg(titles: ["Uploaded", "Skipped", "Failed"], counts: [nUpload, nSkip, nFail])
        let alert = UIAlertController(title: strMsg, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.loadDriveFileList()
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    func uploadLocalPhotos() {
        self.showBusyDialog("Uploading...")

        SyncModule.uploadSelectedLocalPhotos(assets: self.albumPhotos) { (nUpload, nSkip, nFail) in
            DispatchQueue.main.async() {
                self.alertLocalUploadResult(nUpload: nUpload, nSkip: nSkip, nFail: nFail)
            }
        }
    }
    
    func gotoCheckLocalPhotos() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocalAlbum") as? LocalAlbumVC {
            vc.set(viewmode: .upload)
            vc.selectDefaultPhoneAlbum()
            self.bSynchronizeDrive = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func checkAndUploadLocalPhotos() {
        if self.albumPhotos.count <= 0 {
            self.loadDriveFileList()
            return
        }
        
        self.hideBusyDialog()

        let nCount = self.albumPhotos.count
        let strTitle = "There are \(nCount) new photos found at Phone. Do you want to upload them now?"
        let alertController = UIAlertController(title: strTitle, message: nil, preferredStyle: .actionSheet)
        let uploadAction = UIAlertAction(title: "Upload", style: .default) { (_) in
            self.uploadLocalPhotos()
        }
        let reviewAction = UIAlertAction(title: "Review", style: .default) { (_) in
            self.gotoCheckLocalPhotos()
        }
        let neverAction = UIAlertAction(title: "Never alert", style: .default) { (_) in
            self.onFinishSynchronize(turnOffAutoUpload: true)
        }
        let cancelAction = UIAlertAction(title: "Remind me later", style: .cancel) { (_) in
            self.loadDriveFileList()
        }

        alertController.addAction(uploadAction)
        alertController.addAction(reviewAction)
        alertController.addAction(neverAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func fetchFamilyAlbumPhotos() {
        PHModule.getFamilyAlbumAssets { (result) in
            self.albumPhotos = []
            guard let photoList = result else {
                self.loadDriveFileList()
                return
            }
            
            for index in 0 ..< photoList.count {
                let asset = photoList[index]
                if SyncModule.checkPhotoIsUploaded(localIdentifier: asset.localIdentifier) == false {
                    self.albumPhotos += [asset]
                }
            }
            
            self.checkAndUploadLocalPhotos()
        }
    }
    
    func alertDriveUploadResult(nUpload:Int, nSkip: Int, nFail: Int) {
        let strMsg = Global.getProcessResultMsg(titles: ["Uploaded", "Skipped", "Failed"], counts: [nUpload, nSkip, nFail])
        let alert = UIAlertController(title: strMsg, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.onFinishSynchronize(turnOffAutoUpload: false)
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    func uploadDrivePhotos() {
        self.showBusyDialog("Uploading...")

        SyncModule.uploadSelectedDrivePhotos(files: self.drivePhotos) { (nUpload, nSkip, nFail) in
            self.hideBusyDialog()
            self.alertDriveUploadResult(nUpload: nUpload, nSkip: nSkip, nFail: nFail)
        }
    }
    
    func gotoCheckDrivePhotos() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocalAlbum") as? LocalAlbumVC {
            vc.set(viewmode: .upload)
            vc.selectDefaultDriveFolder()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func checkAndUploadDrivePhotos() {
        self.hideBusyDialog()
        
        if self.drivePhotos.count <= 0 {
            self.onFinishSynchronize(turnOffAutoUpload: false)
            return
        }
        
        self.hideBusyDialog()

        let nCount = self.drivePhotos.count
        let strTitle = "There are \(nCount) new photos at Drive. Do you want to upload them now?"
        let alertController = UIAlertController(title: strTitle, message: nil, preferredStyle: .actionSheet)
        let uploadAction = UIAlertAction(title: "Upload", style: .default) { (_) in
            self.uploadDrivePhotos()
        }
        let reviewAction = UIAlertAction(title: "Review", style: .default) { (_) in
            self.gotoCheckDrivePhotos()
        }
        let neverAction = UIAlertAction(title: "Never alert", style: .default) { (_) in
            self.onFinishSynchronize(turnOffAutoUpload: true)
        }
        let cancelAction = UIAlertAction(title: "Remind me later", style: .cancel) { (_) in
            self.onFinishSynchronize(turnOffAutoUpload: false)
        }

        alertController.addAction(uploadAction)
        alertController.addAction(reviewAction)
        alertController.addAction(neverAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func loadDriveFileList() {
        self.showBusyDialog("Synchronize Drive...")

        GDModule.listFiles() { (fileList) in
            self.drivePhotos = []
            
            if let files = fileList?.files {
                for file in files {
                    if SyncModule.checkPhotoIsUploaded(driveFile: file) == false {
                        self.drivePhotos += [file]
                    }
                }
            }

            self.checkAndUploadDrivePhotos()
        }
    }

    func checkAndAutoUpload() {
        if Global.bNeedToSynchronize == false {
            return
        }
        
        Global.bNeedToSynchronize = false

        if Global.bAutoUpload == false {
            self.onFinishSynchronize(turnOffAutoUpload: false)
        } else {
            self.showBusyDialog("Synchronize Phone...")
            //GFSModule.getAllPhotos { (success, photoList) in
                self.fetchFamilyAlbumPhotos()
            //}
        }
    }
    
    func onFinishSynchronize(turnOffAutoUpload: Bool) {
        if turnOffAutoUpload == true {
            self.showBusyDialog()
            GFSModule.updateUser(autoUpload: false) { (success) in
                self.hideBusyDialog()
            }
        }
    }
}

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
    
    @IBOutlet weak var btnToolSelectAll: UIBarButtonItem!
    @IBOutlet weak var btnToolDelete: UIBarButtonItem!
    @IBOutlet weak var btnToolDownload: UIBarButtonItem!

    @IBOutlet weak var btnAdd: UIButton!

    var bEditMode: Bool = false
    var folderPath: String = "central"
    var photoList: [[String:Any]]?
    var selectedPhotoList: [[String:Any]]?
    var backupSelection: [Int] = []

    let activityView = ActivityView()
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
        
        switchModeTo(editMode:false)
    }

    @objc func refresh(_ sender: Any) {
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
        
        // when download completed
        if Global.needDoneSelectionAtHome {
            switchModeTo(editMode: false)
        }
        
        showTabBar()
        if self.bEditMode {
            showToolBar(false)
        }
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
        let fileID = photoInfo["id"] as! String

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
            activityView.showActivityIndicator(self.view, withTitle: "Loading...")
            self.loadFileList()
        }
    }
    
    func switchModeTo(editMode:Bool) {
        self.bEditMode = editMode

        if editMode == true {
            btnNavLeft.image = nil
            btnNavLeft.title = "Cancel"
            btnAdd.isHidden = true
            showToolBar(true)
        } else {
            btnNavLeft.image = UIImage(named:"icon_alarm")
            btnNavLeft.title = ""
            btnAdd.isHidden = false
            hideToolBar(true)
            
            Global.needDoneSelectionAtHome = false
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
        self.selectedPhotoList = [[String:Any]]()
    }
    
    func isSelectedPhoto(_ photoInfo:[String:Any]) -> Bool {
        let photoID = photoInfo["id"] as! String
        guard let photoList = self.selectedPhotoList else { return false }
        
        for item in photoList {
            let id = item["id"] as! String
            if id == photoID {
                return true
            }
        }
        
        return false
    }
    
    func addPhotoToSelectedList(_ photoInfo:[String:Any]) {
        if self.selectedPhotoList == nil {
            return
        }
        
        self.selectedPhotoList! += [photoInfo]
    }
    
    func removePhotoFromSelectedList(_ photoInfo:[String:Any]) {
        guard let photoList = self.selectedPhotoList else { return }
        
        let photoID = photoInfo["id"] as! String
        self.selectedPhotoList = photoList.filter { $0["id"] as! String != photoID }
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
        switchModeTo(editMode:false)
    }
    
    // search (filter) button action
    @IBAction func onBtnNavRight(_ sender: Any) {
        
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

        activityView.showActivityIndicator(self.view, withTitle: "Deleting...")
        
        //for item in self.selectedPhotoList! {
        //}
    }
    
    @IBAction func onBtnDelete(_ sender: Any) {
        if self.selectedPhotoList?.count == 0 {
            alertNoSelection()
            return
        }

        var actions: [(String, UIAlertAction.Style)] = []
        actions.append(("Yes", UIAlertAction.Style.default))
        actions.append(("Cancel", UIAlertAction.Style.cancel))

        //self = ViewController
        Alerts.showActionsheet(viewController: self, title: "Are you sure you delete selected photos?", message: "", actions: actions) { (index) in
            print("call action \(index)")
            if index == 0 {
                
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
}

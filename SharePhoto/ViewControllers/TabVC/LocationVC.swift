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

class LocationVC: BaseVC, UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, QRCodeReaderVCDelegate  {

    enum ViewMode: Int {
       case location = 0
       case upload   = 1
       case download = 2
    }
    
    var frames: [FSFrameInfo] = []
    var viewMode: ViewMode = .location

    @IBOutlet weak var collectionView: UICollectionView!
    //@IBOutlet weak var btnNavLeft: UIBarButtonItem!
    //@IBOutlet weak var btnNavRight: UIBarButtonItem!
    
    let activityView = ActivityView()
    
    open func setView(mode: ViewMode) {
        self.viewMode = mode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.reloadData()
        
        if self.viewMode != .location {
            self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem
        }
        
        if self.viewMode == .upload {
            self.navigationItem.title = "Upload"
        } else if self.viewMode == .download {
            self.navigationItem.title = "Download"
        }
        
        if self.viewMode != .location {
            NotificationCenter.default.addObserver(self, selector: #selector(numberOfUnreadMessagesChanged), name: NSNotification.Name.HCSUnreadMessages, object: nil)
        }
        
        self.loadFrames()
    }
    
    func loadFrames() {
        self.showBusyDialog()
        
        GFSModule.getAllFrames { (success, result) in
            self.hideBusyDialog()
            
            self.frames = result
            self.collectionView.reloadData()
        }
    }

    @objc func numberOfUnreadMessagesChanged() {
        if self.viewMode != .location {
            return
        }
        
        /*
        let messages = Int(HelpCrunch.numberOfUnreadMessages())
        btnNavLeft.addBadge(number: messages)
        if messages > 0 {
            btnNavLeft.addBadge(number: messages)
        } else {
            btnNavLeft.removeBadge()
        }*/
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.collectionView.contentInset = UIEdgeInsets.zero
        
        // manually roate to portrait  mode
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        //self.tabBarController?.tabBar.isHidden = false
        
        hideToolBar(false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.collectionView.collectionViewLayout.invalidateLayout()
        
        if self.viewMode != .location {
            self.numberOfUnreadMessagesChanged()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityView.relayoutPosition(self.view)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.viewMode == .upload { // upload from local or drive
            return 2
        } else if self.viewMode == .location { // location shows only frames
            return frames.count + 1
        } else { // download to all
            return frames.count + 3
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let imgView = cell.viewWithTag(1) as? UIImageView else { return cell }
        guard let label = cell.viewWithTag(2) as? UILabel else { return cell }
        
        let frameCount = frames.count

        if self.viewMode != .location {
            if indexPath.row == 0 {
                label.text = "Local"
                imgView.image = UIImage(named: "loc_phone")
            } else if indexPath.row == 1 {
                imgView.image = UIImage(named: "loc_drive")
                label.text = "Drive"
            } else if indexPath.row == frameCount+2 {
                imgView.image = UIImage(named: "loc_add")
                label.text = "Add Frame"
            } else {
                let index = indexPath.row - 2
                label.text = self.frames[index].title
                imgView.image = UIImage(named: "loc_frame")
            }
        } else {
            if indexPath.row == frameCount {
                imgView.image = UIImage(named: "loc_add")
                label.text = "Add Frame"
            } else {
                let index = indexPath.row
                label.text = self.frames[index].title
                imgView.image = UIImage(named: "loc_frame")
            }
        }
 
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.viewMode == .location {
            if indexPath.row == self.frames.count {
                onChooseAddFrame()
            } else {
                gotoFrameView(index: indexPath.row)
            }
        } else if self.viewMode == .upload {
            if indexPath.row == 0 {
                onChooseLocal()
            } else if indexPath.row == 1 {
                onChooseDrive()
            }
        } else if self.viewMode == .download {
            if indexPath.row == 0 {
                onChooseLocal()
            } else if indexPath.row == 1 {
                onChooseDrive()
            } else if indexPath.row == self.frames.count+2 {
                onChooseAddFrame()
            } else {
                confirmDownloadToFrame(index: indexPath.row-2)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (self.view.frame.size.width - 30)/2
        return CGSize(width:width, height:width)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }

    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func downloadSelectedPhotosToFrame(index: Int) {
        self.activityView.showActivityIndicator(self.view, withTitle: "Downloading...")
        
        let frame = self.frames[index]
        SyncModule.downloadSelectedPhotosToFrame(ID: frame.frameid) { (nDownloaded, nSkipped, nFailed) in
            self.activityView.hideActivitiIndicator()
            
            if nDownloaded > 0 {
                Global.needRefreshLocal = true
            }
            Global.needDoneSelectionAtHome = true
            
            let strMsg = Global.getProcessResultMsg(titles: ["Downloaded", "Skipped", "Failed"], counts: [nDownloaded, nSkipped, nFailed])
            let alert = UIAlertController(title: strMsg, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))

            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func confirmDownloadToFrame(index: Int) {
        let frame = self.frames[index]
        
        let alert = UIAlertController(title: "Download to " + frame.title + "?", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            self.downloadSelectedPhotosToFrame(index: index)
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func gotoFrameView(index: Int) {
        let frame = self.frames[index]
        
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocalAlbum") as? LocalAlbumVC {
            vc.set(viewmode: .show)
            vc.setFrameID(frame.frameid, withTitle:frame.title)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func downloadSelectedPhotosToLocal() {
        self.activityView.showActivityIndicator(self.view, withTitle: "Downloading...")
        
        SyncModule.downloadSelectedPhotosToLocal { (nDownloaded, nSkipped, nFailed) in
            self.activityView.hideActivitiIndicator()
            
            if nDownloaded > 0 {
                Global.needRefreshLocal = true
            }
            Global.needDoneSelectionAtHome = true
            
            let strMsg = Global.getProcessResultMsg(titles: ["Downloaded", "Skipped", "Failed"], counts: [nDownloaded, nSkipped, nFailed])
            let alert = UIAlertController(title: strMsg, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))

            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func onChooseLocal() {
        if self.viewMode == .location {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AlbumsVC") as? AlbumsVC {
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if self.viewMode == .upload {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AlbumsVC") as? AlbumsVC {
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if self.viewMode == .download {
            let alert = UIAlertController(title: "Download to Local?", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                self.downloadSelectedPhotosToLocal()
            }))
            alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func downloadSelectedPhotosToDrive() {
        self.activityView.showActivityIndicator(self.view, withTitle: "Downloading...")
        
        SyncModule.downloadSelectedPhotosToDrive { (nDownloaded, nSkipped, nFailed) in
            self.activityView.hideActivitiIndicator()
            
            if nDownloaded > 0 {
                Global.needRefreshLocal = true
            }
            Global.needDoneSelectionAtHome = true
            
            let strMsg = Global.getProcessResultMsg(titles: ["Downloaded", "Skipped", "Failed"], counts: [nDownloaded, nSkipped, nFailed])
            let alert = UIAlertController(title: strMsg, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))

            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func onChooseDrive() {
        if self.viewMode == .location {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocalAlbum") as? LocalAlbumVC {
                vc.set(viewmode: .show)
                vc.selectDefaultDriveFolder()
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if self.viewMode == .upload {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocalAlbum") as? LocalAlbumVC {
                vc.set(viewmode: .upload)
                vc.selectDefaultDriveFolder()
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if self.viewMode == .download {
            let alert = UIAlertController(title: "Download to Drive?", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                self.downloadSelectedPhotosToDrive()
            }))
            alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func registerRPIFrame(ID: String, title: String) {
        self.showBusyDialog()
        
        GFSModule.registerRPIFrame(ID: ID, title: title) { (success) in
            self.hideBusyDialog()

            self.loadFrames()
        }
    }
    
    func alertFrameAlreadyRegistered() {
        let alertController = UIAlertController(title: "Frame already registered", message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "OK", style: .default) { (_) in
        }

        alertController.addAction(confirmAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func inputFrameNameAndRegister(frameID: String) {
        let alertController = UIAlertController(title: "Frame name", message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Add", style: .default) { (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                self.registerRPIFrame(ID: frameID, title: text)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        alertController.addTextField { (textField) in
            textField.text = ""
            textField.placeholder = "Frame name"
        }

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func checkAlreadyRegistered(frameID: String) -> Bool {
        for i in 0..<self.frames.count {
            let frame = self.frames[i]
            if frame.frameid.compare(frameID) == .orderedSame {
                return true
            }
        }

        return false
    }
    
    func onFoundRPIFrame(ID: String) {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.25) {
            if self.checkAlreadyRegistered(frameID: ID) {
                self.alertFrameAlreadyRegistered()
            } else {
                self.inputFrameNameAndRegister(frameID: ID)
            }
        }
    }
    
    func gotoQRCodeReader() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QRCodeReaderVC") as? QRCodeReaderVC {
            vc.modalPresentationStyle = .fullScreen
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func gotoOrder() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OrderVC") as? OrderVC {
            vc.modalPresentationStyle = .fullScreen
//            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
//            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func onChooseAddFrame() {
        let alert = UIAlertController(title: "Register or order a frame?", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Register", style: .default, handler: { _ in
            self.gotoQRCodeReader()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Order", style: .default, handler: { _ in
            self.gotoOrder()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func hideToolBar(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }

    func showToolBar(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    @IBAction func onAddPhoto(_ sender: UIButton) {
        
    }
    
    @IBAction func onBtnNavLeft(_ sender: Any) {
        HelpCrunch.show(from: self) { (error) in
        }
    }
    
    // search (filter) button action
    @IBAction func onBtnNavRight(_ sender: Any) {
        
    }
}

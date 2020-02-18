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

class LocationVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout  {

    enum ViewMode: Int {
       case location = 0
       case upload = 1
       case download = 2
    }
    
    let frameCount = 0
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
        if self.viewMode == .location {
            return frameCount+1
        } else {
            return frameCount+3
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let imgView = cell.viewWithTag(1) as? UIImageView else { return cell }
        guard let label = cell.viewWithTag(2) as? UILabel else { return cell }

        if self.viewMode != .location {
            if indexPath.row == 0 {
                label.text = "Local"
                imgView.image = UIImage(named: "loc_phone")
            } else if indexPath.row == 1 {
                imgView.image = UIImage(named: "loc_drive")
                label.text = "Drive"
            } else if indexPath.row == frameCount {
                imgView.image = UIImage(named: "loc_add")
                label.text = "Add Frame"
            } else {
                imgView.image = UIImage(named: "loc_frame")
                label.text = "Frame"
            }
        } else {
            if indexPath.row == frameCount {
                imgView.image = UIImage(named: "loc_add")
                label.text = "Add Frame"
            } else {
                imgView.image = UIImage(named: "loc_frame")
                label.text = "Frame"
            }
        }
 
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.viewMode != .location {
            if indexPath.row == 0 {
                onChooseLocal()
            } else if indexPath.row == 1 {
                onChooseDrive()
            } else {
                onChooseAddFrame()
            }
        } else {
            onChooseAddFrame()
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
            /*
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocalAlbum") as? LocalAlbumVC {
                vc.set(viewmode: .show)
                vc.selectDefaultPhoneAlbum()
                navigationController?.pushViewController(vc, animated: true)
            }*/
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AlbumsVC") as? AlbumsVC {
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if self.viewMode == .upload {
            /*
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocalAlbum") as? LocalAlbumVC {
                vc.set(viewmode: .upload)
                vc.selectDefaultPhoneAlbum()
                navigationController?.pushViewController(vc, animated: true)
            }*/
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
    
    func onChooseAddFrame() {
        let alert = UIAlertController(title: "Will be implemented soon.", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Ok", style: .cancel, handler: nil))
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

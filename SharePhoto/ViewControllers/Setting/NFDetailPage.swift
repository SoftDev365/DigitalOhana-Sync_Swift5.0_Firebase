//
//  NFDetailPage.swift
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

class NFDetailPage: BaseVC, UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    var photoList: [FSPhotoInfo]?

    let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        //self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.isNavigationBarHidden = false
        
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: attributes)
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        refreshControl.tintColor = .white
        
        self.collectionView.addSubview(refreshControl) // not required when using UITableViewController
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

        showTabBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        refreshFileList()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func loadFileList() {
        //GFSModule.getAllPhotos { (success, result) in
        GFSModule.searchPhotosBy(options: Global.notificationOption) { (success, result) in
            self.refreshControl.endRefreshing()
            self.hideBusyDialog()
            
            if !success {
                return
            }
            
            self.photoList = result
            self.collectionView.reloadData()
        }
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

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell

        guard let photoList = self.photoList else { return cell }
        let row = indexPath.row

        let photoInfo = photoList[row]
        let fileID = photoInfo.id

        cell.setCloudFile(fileID)
        cell.setSelectable(false)
       
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SlideVC") as? GSGalleryVC {
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
        self.showBusyDialog("Loading...")
        self.loadFileList()
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
}

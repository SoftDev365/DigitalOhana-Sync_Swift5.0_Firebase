//
//  LocalGalleryVC.swift
//  Local Photo Album Gallery
//
//  Created by Admin on 11/14/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import Photos
import GoogleAPIClientForREST

class LocalGalleryVC: UIViewController, UIScrollViewDelegate {

    enum SourceType: Int {
        case local = 0
        case drive = 1
        case raspberrypi = 2
    }

    var sourceType: SourceType = .local
    var albumPhotos: [PHAsset]? = nil
    var drivePhotos: [GTLRDrive_File]?
    
    var imgViewList: [ImageZoomView]?
    var curPage: Int = 0
    var bIsFullscreen = false
    
    @IBOutlet weak var scrView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var btnUpload: UIBarButtonItem!
    
    let activityView = ActivityView()
    
    override open var shouldAutorotate: Bool {
        return true
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    func setAlbumPhotos(_ photos: [PHAsset], page:Int) {
        self.albumPhotos = photos
        self.curPage = page
        self.sourceType = .local
    }
    
    func setDrivePhotos(_ photos: [GTLRDrive_File], page:Int) {
        self.drivePhotos = photos
        self.curPage = page
        self.sourceType = .drive
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.view.addGestureRecognizer(tap)
        
        self.contentView.removeFromSuperview()
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard sender.view != nil else {
            return
        }
        
        bIsFullscreen = !bIsFullscreen

        self.navigationController!.isNavigationBarHidden = bIsFullscreen
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var prefersStatusBarHidden: Bool {
        return bIsFullscreen
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        initContentImageViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        //initContentImageViews()
    }
    
    func getPhotoCount() -> Int {
        if self.sourceType == .local {
            return self.albumPhotos?.count ?? 0
        } else {
            return self.drivePhotos?.count ?? 0
        }
    }
    
    func createPhotoView(index: Int) -> ImageZoomView {
        if self.sourceType == .local {
            return ImageZoomView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), asset: self.albumPhotos![index])
        } else {
            return ImageZoomView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), driveFile: self.drivePhotos![index])
        }
    }
    
    func initContentImageViews() {
        
        let nCount = getPhotoCount()
        self.imgViewList = [ImageZoomView]()

        for i in 0..<nCount {
            let item = createPhotoView(index: i)
            if abs(i - self.curPage) <= 1 {
                item.showImage()
            } else if abs(i - self.curPage) > 2 {
                item.hideImage()
            }

            self.imgViewList!.append(item)
            self.scrView.addSubview(item)
        }
        
        self.scrView.isPagingEnabled = true
        self.scrView.delegate = self
        
        self.relayoutImageViews(false)
    }
    
    func isUploadedPhoto(at: Int) -> Bool {
        if self.sourceType == .local {
            guard let photoList = self.albumPhotos else { return false }
            let asset = photoList[curPage]
            
            // hide upload button if already uploaded
            return SyncModule.checkPhotoIsUploaded(localIdentifier: asset.localIdentifier)
        } else {
            //guard let photoList = self.drivePhotos else { return false }
            //let file = photoList[curPage]
            //return SyncModule.checkPhotoIsUploaded(driveFile: file)
            return true
        }
    }
    
    func refreshUploadButtonStatus() {
        // hide upload button if already uploaded
        if isUploadedPhoto(at:curPage) == true {
            btnUpload.isEnabled = false
            btnUpload.tintColor = UIColor.clear
        } else {
            btnUpload.isEnabled = true
            btnUpload.tintColor = UIColor.white
        }
    }
    
    func relayoutImageViews(_ recalcZoomScale:Bool) {
        guard let imgViewList = self.imgViewList else { return }
        
        let size = self.scrView.bounds.size
        let w = size.width
        let h = size.height
        
        for i in 0...(imgViewList.count-1) {
            let item = imgViewList[i]
            let rect = CGRect(x: w*CGFloat(i), y: 0, width: w, height: h)
            item.frame = rect
            
            if recalcZoomScale {
                item.recalcZoomScale()
            }
        }
        
        self.scrView.contentSize = CGSize(width: w*CGFloat(imgViewList.count), height: h)
        self.scrView.contentOffset = CGPoint(x: w*CGFloat(curPage), y: 0)
        self.scrView.isPagingEnabled = true
        self.scrView.delegate = self
        
        refreshUploadButtonStatus()
    }
    
    func recalcZoomScaleOfPhotos() {
        relayoutImageViews(true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let imgViewList = self.imgViewList else { return }

        curPage = (Int)(self.scrView.contentOffset.x / self.scrView.bounds.width)
        
        for i in 0...(imgViewList.count-1) {
            let item = imgViewList[i]
            
            if i != curPage {
                item.fitViewSizeToImage()
            }
            
            if abs(i - self.curPage) <= 1 {
                item.showImage()
            } else if abs(i - self.curPage) > 2 {
                item.hideImage()
            }
        }
        
        refreshUploadButtonStatus()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        curPage = (Int)(self.scrView.contentOffset.x / self.scrView.bounds.width)
        refreshUploadButtonStatus()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        recalcZoomScaleOfPhotos()
    }
    
    func uploadPhoto(asset: PHAsset) {
        activityView.showActivityIndicator(self.view, withTitle: "Uploading...")
        SyncModule.uploadPhoto(asset: asset) { (success) in
            self.activityView.hideActivitiIndicator()
            self.refreshUploadButtonStatus()
            
            Global.setNeedRefresh()
        }
    }
    
    @IBAction func onBtnUpload(_ sender: Any) {
        guard let photoList = self.albumPhotos else { return }
        let asset = photoList[curPage]

        uploadPhoto(asset: asset)
    }
}

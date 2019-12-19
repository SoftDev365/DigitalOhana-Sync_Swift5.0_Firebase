//
//  GSGalleryVC.swift
//  Google Storage Photo Gallery
//
//  Created by Admin on 11/14/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit

class GSGalleryVC: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var btnDownload: UIBarButtonItem!
    
    var photoList: [[String:Any]]?
    var imgViewList: [ImageZoomView]?
    var curPage: Int = 0
    var bIsFullscreen = false
    
    let activityView = ActivityView()
    
    override open var shouldAutorotate: Bool {
        return true
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    func setFileList(_ list: [[String:Any]], page:Int) {
        self.photoList = list
        self.curPage = page
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.tabBar.isHidden = true//bIsFullscreen
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        initContentImageViews()
    }
    
    func initContentImageViews() {
        if self.imgViewList != nil {
            return
        }
        
        guard let photoList = self.photoList else { return }
        
        self.imgViewList = [ImageZoomView]()

        for i in 0..<photoList.count {
            
            let photoInfo = photoList[i]
            let fileID = photoInfo["id"] as! String
            
            let item = ImageZoomView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), fileID: fileID)
            if abs(i - self.curPage) <= 1 {
                item.showImage()
            }
            
            self.imgViewList!.append(item)
            self.scrView.addSubview(item)
        }
        
        self.scrView.isPagingEnabled = true
        self.scrView.delegate = self
        
        self.relayoutImageViews(false)
    }
    
    func refreshDownloadButtonStatus() {
        guard let photoList = self.photoList else { return }
        let photoInfo = photoList[curPage]
        let fsID = photoInfo["id"] as! String
        
        // hide download button if already downloaded
        if SyncModule.checkPhotoIsDownloaded(fileID: fsID) == true {
            btnDownload.isEnabled = false
            btnDownload.tintColor = UIColor.clear
        } else {
            btnDownload.isEnabled = true
            btnDownload.tintColor = UIColor.white
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
        
        refreshDownloadButtonStatus()
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
            }
        }
        
        refreshDownloadButtonStatus()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        curPage = (Int)(self.scrView.contentOffset.x / self.scrView.bounds.width)
        refreshDownloadButtonStatus()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        recalcZoomScaleOfPhotos()
    }
    
    func downloadImage(image: UIImage, photoInfo: [String: Any]) {
        activityView.showActivityIndicator(self.view, withTitle: "Loading...")
        SyncModule.downloadImage(photoInfo: photoInfo, image: image) { (success) in
            DispatchQueue.main.sync {
                self.activityView.hideActivitiIndicator()
                // update UI
                self.refreshDownloadButtonStatus()
                
                Global.setNeedRefresh()
            }
        }
    }
    
    @IBAction func onBtnDownload(_ sender: Any) {
        guard let photoList = self.photoList else { return }
        let photoInfo = photoList[curPage]
        let itemVieww = self.imgViewList![curPage]
        
        if let image = itemVieww.imgView!.image {
            downloadImage(image: image, photoInfo: photoInfo)
        }
    }
}

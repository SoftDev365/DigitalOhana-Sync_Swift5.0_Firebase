//
//  GalleryVC.swift
//  Local Photo Album Gallery
//
//  Created by Admin on 11/14/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import Photos

class GalleryVC: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    var albumPhotos: PHFetchResult<PHAsset>? = nil
    var imgViewList: [ImageZoomView]?
    var curPage: Int = 0
    var bIsFullscreen = false
    
    override open var shouldAutorotate: Bool {
        return true
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    func setPhotoAlbum(_ photos: PHFetchResult<PHAsset>, page:Int) {
        self.albumPhotos = photos
        self.curPage = page
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.view.addGestureRecognizer(tap)
        
        self.contentView.removeFromSuperview()
        
        //self.tabBarController?.tabBar.isHidden = true
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard sender.view != nil else {
            return
        }
        
        bIsFullscreen = !bIsFullscreen
        if bIsFullscreen {
            self.scrView.backgroundColor = UIColor.black
        } else {
            self.scrView.backgroundColor = UIColor.white
        }
        
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
        guard let photoList = self.albumPhotos else { return }
        
        self.imgViewList = [ImageZoomView]()

        for i in 0...(photoList.count-1) {
            let item = ImageZoomView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), asset: photoList[i])
            self.imgViewList!.append(item)
            self.scrView.addSubview(item)
        }
        
        self.scrView.isPagingEnabled = true
        self.scrView.delegate = self
        
        self.relayoutImageViews(false)
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
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        curPage = (Int)(self.scrView.contentOffset.x / self.scrView.bounds.width)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        recalcZoomScaleOfPhotos()
    }
}

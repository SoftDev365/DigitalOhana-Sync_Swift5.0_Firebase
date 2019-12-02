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
    
    var photoList: [[String:Any]]?
    var imgViewList: [ImageZoomView]?
    var curPage: Int = 0
    
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.view.addGestureRecognizer(tap)
        
        self.contentView.removeFromSuperview()
        //self.tabBarController?.tabBar.isHidden = true
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard sender.view != nil else {
            return
        }
        
        self.navigationController!.isNavigationBarHidden = !self.navigationController!.isNavigationBarHidden
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
        
        self.relayoutImageItemViews(self.scrView.bounds.size)
    }
    
    func relayoutImageItemViews(_ size: CGSize) {
        if self.imgViewList == nil {
            return
        }

        let w = size.width
        let h = size.height

        for i in 0...(self.imgViewList!.count-1) {
            let rect = CGRect(x: w*CGFloat(i), y: 0, width: w, height: h)
            //self.imgViewList![i].setZoomScale(1.0, animated: false)
            self.imgViewList![i].frame = rect
            //self.imgViewList![i].setZoomScale(1.0, animated: false)
            self.imgViewList![i].fitViewSizeToImage()
        }
        
        //self.contentView.frame = CGRect(x: 0, y: 0, width: w*CGFloat(self.imgViewList!.count), height: h)
        self.scrView.contentSize = CGSize(width: w*CGFloat(self.imgViewList!.count), height: h)
        self.scrView.contentOffset = CGPoint(x: w*CGFloat(curPage), y: 0)
        self.scrView.isPagingEnabled = true
        self.scrView.delegate = self
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.imgViewList == nil {
            return
        }
        
        curPage = (Int)(self.scrView.contentOffset.x / self.scrView.bounds.width)
        
        for i in 0...(imgViewList!.count-1) {
            let item = imgViewList![i]
            
            if i != curPage {
                //item.setZoomScale(1.0, animated: false)
                item.fitViewSizeToImage()
            }
            
            if abs(i - self.curPage) <= 1 {
                item.showImage()
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        //self.relayoutImageItemViews(size)
        curPage = (Int)(self.scrView.contentOffset.x / self.scrView.bounds.width)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.relayoutImageItemViews(self.scrView.bounds.size)
    }
}

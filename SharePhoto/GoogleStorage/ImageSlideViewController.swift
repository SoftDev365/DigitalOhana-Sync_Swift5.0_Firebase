//
//  ImageSlideViewController.swift
//  SharePhoto
//
//  Created by Admin on 11/14/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit

class ImageSlideViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    var fileList: [StorageItem]!
    var imgViewList: [ImageZoomView]?
    
    var orientationLock = UIInterfaceOrientationMask.all

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
            return self.orientationLock
    }
    
    func setFileList(_ list: [StorageItem]) {
        self.fileList = list
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        initContentImageViews()
    }
    
    func initContentImageViews() {
        if self.imgViewList != nil {
            return
        }
        
        self.imgViewList = [ImageZoomView]()
        
        let w = self.scrView.bounds.size.width
        let h = self.scrView.bounds.size.height

        for i in 0...(fileList.count-1) {
            if fileList![i].isFolder == true {
                continue
            }
            
            let index = self.imgViewList!.count
            let rect = CGRect(x: w*CGFloat(index), y: 0, width: w, height: h)
            let item = ImageZoomView(frame: rect, file: fileList[i].file)
            
            self.imgViewList!.append(item)
            self.scrView.addSubview(item)
        }
        
        self.contentView.frame = CGRect(x: 0, y: 0, width: w*CGFloat(self.imgViewList!.count), height: h)
        self.scrView.contentSize = CGSize(width: w*CGFloat(self.imgViewList!.count), height: h)
        self.scrView.isPagingEnabled = true
        self.scrView.delegate = self
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.imgViewList == nil {
            return
        }
        
        let curPage = (Int)(self.scrView.contentOffset.x / self.scrView.bounds.width)
        
        for i in 0...(imgViewList!.count-1) {
            let item = imgViewList![i]
            
            if i != curPage {
                item.setZoomScale(1.0, animated: false)
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

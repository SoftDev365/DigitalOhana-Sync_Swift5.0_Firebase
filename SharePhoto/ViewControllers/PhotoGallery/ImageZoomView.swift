//
//  ImageZoomView.swift
//  SharePhoto
//
//  Created by Admin on 11/14/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import Foundation
import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import Firebase
import FirebaseStorage
import Photos

class ImageZoomView: UIScrollView, UIScrollViewDelegate {

    let sharedFolder = "central"
    var strGSFileID: String? = nil
    var bDownloadStarted = false
    var imgView: UIImageView? = nil

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(frame: CGRect, fileID: String) {
        super.init(frame: frame)

        initControls()
        self.strGSFileID = fileID
        self.bDownloadStarted = false
    }
    
    init(frame: CGRect, asset: PHAsset) {
        super.init(frame: frame)

        initControls()
        
        let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        PHCachingImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil) { (image, _) in
            self.imgView!.image = image
            self.imgView!.contentMode = .scaleAspectFit
            self.fitViewSizeToImage()
        }
    }
    
    func showImage() {
        guard let fileID = self.strGSFileID else { return }
        if self.bDownloadStarted == true {
            return
        }
        
        self.bDownloadStarted = false
        GSModule.downloadImageFile(fileID: fileID, folderPath: self.sharedFolder) { (image) in
            self.imgView!.image = image
            self.imgView!.contentMode = .scaleAspectFit
            self.fitViewSizeToImage()
        }
    }
    
    func initControls() {
        self.delegate = self
        
        self.imgView = UIImageView()
        self.imgView!.frame = self.bounds
        self.imgView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(self.imgView!)
        
        //self.imgView!.centerXAnchor.constraint(equalTo: self.contentLayoutGuide.centerXAnchor).isActive = true
        //self.imgView!.centerYAnchor.constraint(equalTo: self.contentLayoutGuide.centerYAnchor).isActive = true

        self.autoresizesSubviews = true
        
        self.minimumZoomScale = 1.0
        self.maximumZoomScale = 5.0
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
    }
    
    func recalcZoomScale() {
        
        let orgScale = self.zoomScale
        
        self.zoomScale = 1.0
        
        guard let imgView = self.imgView else { return }
        guard let image = imgView.image else { return }

        let size = self.bounds.size
        let wr = UIScreen.main.scale*size.width/image.size.width
        let hr = UIScreen.main.scale*size.height/image.size.height
        
        if wr < hr {
            let w = size.width
            let h = w*image.size.height/image.size.width
            //imgView.frame = CGRect(x: 0, y: (size.height-h)/2, width: w, height: h)
            imgView.frame = CGRect(x: 0, y: 0, width: w, height: h)
            self.minimumZoomScale = 1.0
            self.maximumZoomScale = 1/wr
        } else {
            let h = size.height
            let w = h*image.size.width/image.size.height
            //imgView.frame = CGRect(x: (size.width-w)/2, y: 0, width: w, height: h)
            imgView.frame = CGRect(x: 0, y: 0, width: w, height: h)
            self.minimumZoomScale = 1.0
            self.maximumZoomScale = 1/hr
        }

        self.zoomScale = orgScale
        
        moveCotentToCenter()
    }
    
    func fitViewSizeToImage() {
        self.zoomScale = 1.0
        recalcZoomScale()
        self.zoomScale = 1.0
        
        moveCotentToCenter()
    }
    
    func moveCotentToCenter() {
        let offsetX = max((self.bounds.width - self.contentSize.width) * 0.5, 0)
        let offsetY = max((self.bounds.height - self.contentSize.height) * 0.5, 0)
        self.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imgView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        moveCotentToCenter()
    }
}

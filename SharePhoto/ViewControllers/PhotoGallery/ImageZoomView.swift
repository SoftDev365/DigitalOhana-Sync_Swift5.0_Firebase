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

    enum SourceType: Int {
       case asset = 0
       case drive = 1
       case cloud = 2
    }
    
    var sourceType: SourceType = .asset
 
    // local photo album source
    var sourceAsset: PHAsset? = nil
    
    // google drive photo source
    var sourceDriveFile: GTLRDrive_File? = nil

    // google cloud photo source
    let sharedFolder = "central"
    var sourceCloudID: String? = nil
    
    var scaledSize: CGSize = CGSize(width: 0, height: 0)

    // now loading photo
    var bLoading = false
    var bLoaded = false
    
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
        
        self.sourceType = .cloud
        self.sourceCloudID = fileID
        self.bLoading = false
    }
    
    init(frame: CGRect, asset: PHAsset) {
        super.init(frame: frame)

        initControls()
        
        self.sourceType = .asset
        self.sourceAsset = asset
        self.bLoading = false
    }
    
    init(frame: CGRect, driveFile: GTLRDrive_File) {
        super.init(frame: frame)

        initControls()
        
        self.sourceType = .drive
        self.sourceDriveFile = driveFile
        self.bLoading = false
    }
    
    func loadLocalPhoto() {
        guard let asset = self.sourceAsset else {
            self.bLoading = false
            self.imgView?.image = nil
            return
        }
        
        let options = PHImageRequestOptions()
        //options.deliveryMode = .highQualityFormat
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true

        options.progressHandler = {  (progress, error, stop, info) in
            print("progress: \(progress)")
        }
        
        let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        //let size = UIScreen.main.bounds.size
        PHCachingImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { (image, info) in
            self.bLoading = false
            self.bLoaded = true
            
            // skip twice calls
            //let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            //if isDegraded {
            //   return
            //}
            
            if image == nil {
                return
            }
            
            self.imgView!.image = image
            self.imgView!.contentMode = .scaleAspectFit
            self.fitViewSizeToImage()
        }
        
        /*
        PHImageManager.default().requestImageData(for: asset, options: PHImageRequestOptions(), resultHandler: { (data, string, orient, info) in
            self.bLoading = false
            
            //if string?.range(of: ".heic") != nil || string?.range(of: ".heif") != nil {
            if data != nil {
                let image = UIImage(data: data!)
                self.bLoaded = true
                
                if image == nil {
                    return
                }
                
                self.imgView!.image = image
                self.imgView!.contentMode = .scaleAspectFit
                self.fitViewSizeToImage()
            //} else {
            //}
            }
        })*/
    }
    
    func loadCloudPhoto() {
        guard let fileID = self.sourceCloudID else {
            self.bLoading = false
            self.imgView?.image = nil
            return
        }

        GSModule.downloadImageFile(cloudFileID: fileID, folderPath: self.sharedFolder) { (fileID, image) in
            self.bLoading = false
            self.bLoaded = true
            self.imgView!.image = image
            self.imgView!.contentMode = .scaleAspectFit
            self.fitViewSizeToImage()
        }
    }
    
    func loadDrivePhoto() {
        guard let file = self.sourceDriveFile else {
            self.bLoading = false
            self.imgView?.image = nil
            return
        }
        
        // download thumbnail first
        if let thumnailLink = file.thumbnailLink {
            GDModule.downloadThumnail(urlString: thumnailLink) { (url, image) in
                // already loaded full image
                if self.bLoaded == true {
                    return
                }
                self.imgView!.image = image
                self.imgView!.contentMode = .scaleAspectFit
                self.fitViewSizeToImage()
            }
        }
        
        GDModule.downloadImage(fileID: file.identifier!) { (fileID, image) in
            self.bLoading = false
            self.bLoaded = true
            self.imgView!.image = image
            self.imgView!.contentMode = .scaleAspectFit
            self.fitViewSizeToImage()
        }
    }
    
    func showImage() {
        if self.bLoaded == true {
            if let imgView = self.imgView {
                if imgView.image != nil {
                    return
                }
            }
        }
        
        if self.bLoading == true {
            return
        }
        
        self.bLoading = true
        
        switch self.sourceType {
        case .asset:
            loadLocalPhoto()
        case .drive:
            loadDrivePhoto()
        case .cloud:
            loadCloudPhoto()
        }
    }
    
    func hideImage() {
        if self.bLoaded == true {
            self.bLoaded = false
            self.imgView?.image = nil
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

        guard let imgView = self.imgView else { return }
        guard let image = imgView.image else { return }

        let imageSize = image.size
        let size = self.bounds.size
        let wr = size.width/imageSize.width
        let hr = size.height/imageSize.height
        
        self.minimumZoomScale = 1.0
        self.maximumZoomScale = 1.0
        self.zoomScale = 1.0
        imgView.frame = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        self.minimumZoomScale = min(wr, hr)
        self.maximumZoomScale = max(self.minimumZoomScale, 1.0)
        self.zoomScale = self.minimumZoomScale
        
        moveCotentToCenter()
    }

    /*
    func getImageSize() -> CGSize {
        if self.sourceType == .asset {
            if let asset = self.sourceAsset {
                let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                return size
            }
        }

        let defSize = self.frame.size
        guard let imgView = self.imgView else {
            return defSize
        }

        guard let image = imgView.image else {
            return defSize
        }

        return image.size
    }
     
    func recalcZoomScale() {

        guard let imgView = self.imgView else { return }
        guard let image = imgView.image else { return }

        let size = self.bounds.size
        let imageSize = getImageSize()
        
        /*
        if self.scaledSize.equalTo(imageSize) {
            moveCotentToCenter()
            return
        }
        self.scaledSize = imageSize*/
        
        let wr = UIScreen.main.scale*size.width/imageSize.width
        let hr = UIScreen.main.scale*size.height/imageSize.height
        
        //let orgScale = self.zoomScale
        self.zoomScale = 1.0
        
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

        //self.zoomScale = orgScale
        self.zoomScale = 1.0
        
        moveCotentToCenter()
    }*/
    
    func fitViewSizeToImage() {
        recalcZoomScale()
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

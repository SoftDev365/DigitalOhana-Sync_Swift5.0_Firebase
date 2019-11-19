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

class ImageZoomView: UIScrollView, UIScrollViewDelegate {
    
    var file: StorageReference?
    var imgView: UIImageView?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(frame: CGRect, file: StorageReference) {
        super.init(frame: frame)

        self.file = file
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
        
        GSModule.downloadImageFile(file) { (image) in
            self.imgView!.image = image
            self.imgView!.contentMode = .scaleAspectFit
            self.fitViewSizeToImage()
        }
    }
    
    func fitViewSizeToImage() {
        self.zoomScale = 1.0
        
        guard let imgView = self.imgView else { return }
        guard let image = imgView.image else { return }

        let size = self.bounds.size
        let wr = size.width/image.size.width
        let hr = size.height/image.size.height
        
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

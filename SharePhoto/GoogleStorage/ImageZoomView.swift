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

        self.autoresizesSubviews = true
        
        self.minimumZoomScale = 1.0
        self.maximumZoomScale = 5.0
        
        GSModule.downloadImageFile(file) { (image) in
            self.imgView!.image = image
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imgView
    }
}

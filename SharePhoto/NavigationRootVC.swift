//
//  NavigationRootVC.swift
//  Navigation Root Controller for Orientation Process
//
//  Created by Admin on 11/18/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit

class NavigationRootVC: UINavigationController {

    override open var shouldAutorotate: Bool {
        if visibleViewController is ImageSlideVC {
            return true
        }
        if visibleViewController is GalleryVC {
            return true
        }
        if visibleViewController is PhotoCollectionViewController {
            return true
        }
        
        return false
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if visibleViewController is ImageSlideVC {
            return .all
        }
        if visibleViewController is GalleryVC {
            return .all
        }
        if visibleViewController is PhotoCollectionViewController {
            return .all
        }

        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}

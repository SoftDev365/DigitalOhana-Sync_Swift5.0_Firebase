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
        if visibleViewController is GSGalleryVC {
            return true
        }
        if visibleViewController is LocalGalleryVC {
            return true
        }
        if visibleViewController is GSAlbumVC {
            return true
        }
        
        return false
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if visibleViewController is GSGalleryVC {
            return .all
        }
        if visibleViewController is LocalGalleryVC {
            return .all
        }
        if visibleViewController is GSAlbumVC {
            return .all
        }

        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}

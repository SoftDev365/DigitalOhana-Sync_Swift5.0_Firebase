//
//  MainVC.swift
//  
//
//  Created by Admin on 11/25/19.
//

import UIKit

class MainVC: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override open var shouldAutorotate: Bool {
        if selectedViewController is CustomNavigationController {
            return selectedViewController!.shouldAutorotate
        }
        /*
        if visibleViewController is ImageSlideVC {
            return true
        }
        if visibleViewController is GalleryVC {
            return true
        }
        if visibleViewController is PhotoCollectionViewController {
            return true
        }*/
        
        return false
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        
        if selectedViewController is CustomNavigationController {
            return selectedViewController!.supportedInterfaceOrientations
        }
        /*
        if visibleViewController is ImageSlideVC {
            return .all
        }
        if visibleViewController is GalleryVC {
            return .all
        }
        if visibleViewController is PhotoCollectionViewController {
            return .all
        }*/

        return .portrait
    }

}

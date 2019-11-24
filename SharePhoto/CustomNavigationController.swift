//
//  CustomNavigationController.swift
//  SharePhoto
//
//  Created by Admin on 11/18/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit

class CustomNavigationController: UINavigationController {

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

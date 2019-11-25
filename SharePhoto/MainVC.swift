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
        if selectedViewController is NavigationRootVC {
            return selectedViewController!.shouldAutorotate
        }

        return false
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        
        if selectedViewController is NavigationRootVC {
            return selectedViewController!.supportedInterfaceOrientations
        }

        return .portrait
    }

}

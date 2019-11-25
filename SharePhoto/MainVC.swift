//
//  MainVC.swift
//  
//
//  Created by Admin on 11/25/19.
//

import UIKit

class MainVC: UITabBarController, UITabBarControllerDelegate {
    @IBOutlet weak var btnUpload: UIBarButtonItem!
    
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
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("Selected item")
        if item.tag == 1 {
            self.navigationItem.title = "Family Album"
            btnUpload.image = UIImage.init(systemName: "plus.square")
        } else {
            self.navigationItem.title = "Shared Storage"
            btnUpload.image = UIImage.init(systemName: "square.and.arrow.up")
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("Selected view controller")
    }
    
    @IBAction func onBtnSignout(_ sender: Any) {
    }
    
    @IBAction func onBtnReload(_ sender: Any) {
    }
    
    @IBAction func onBtnUpload(_ sender: Any) {
    }
}

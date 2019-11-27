//
//  MainVC.swift
//  
//
//  Created by Admin on 11/25/19.
//

import UIKit
import Firebase
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import Photos

class MainVC: UITabBarController, UITabBarControllerDelegate, ImagePickerModuleDelegate {
    @IBOutlet weak var btnUpload: UIBarButtonItem!
    
    let activityView = ActivityView()
    var imagePicker = UIImagePickerController()
    var imagePickerModule: ImagePickerModule!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePickerModule = ImagePickerModule(self)
        imagePickerModule.delegate = self
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
    
    func doLogout() {
        let alert = UIAlertController(title: "Are you sure you log out?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            GIDSignIn.sharedInstance()?.signOut()
            self.navigationController!.dismiss(animated: true, completion: nil)
        }))

        alert.addAction(UIAlertAction(title: "No", style: .default, handler: { _ in
            
        }))

        self.present(alert, animated: true, completion: nil)
    }

    func imagePickerModule(_ module: ImagePickerModule, completeWithImage image: UIImage) {
        if selectedIndex == 0 {
            let vc = selectedViewController as! LocalAlbumVC
            vc.addPhotoToLocalAlbum(image)
        } else {
            
        }
    }
    
    @IBAction func onBtnSignout(_ sender: Any) {
        doLogout()
    }

    @IBAction func onBtnReload(_ sender: Any) {
        if selectedIndex == 0 {
            let vc = selectedViewController as! LocalAlbumVC
            vc.refreshAlbum()
        } else {
            
        }
    }
    
    @IBAction func onBtnUpload(_ sender: Any) {
        imagePickerModule.startImagePicking()
    }
}

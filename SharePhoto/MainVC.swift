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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = false//bIsFullscreen
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
            self.navigationItem.title = "Home"
            if #available(iOS 13.0, *) {
                btnUpload.image = UIImage.init(systemName: "plus.square")
            } else {
                // Fallback on earlier versions
            }
        } else if item.tag == 2 {
            self.navigationItem.title = "Location"
            if #available(iOS 13.0, *) {
                btnUpload.image = UIImage.init(systemName: "square.and.arrow.up")
            } else {
                // Fallback on earlier versions
            }
        } else {
            self.navigationItem.title = "Setting"
            if #available(iOS 13.0, *) {
                btnUpload.image = UIImage.init(systemName: "square.and.arrow.up")
            } else {
                // Fallback on earlier versions
            }
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
            let vc = selectedViewController as! GSAlbumVC
            vc.uploadPhoto(image)
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
            let vc = selectedViewController as! GSAlbumVC
            vc.refreshFileList()
        }
    }
    
    @IBAction func onBtnUpload(_ sender: Any) {
        imagePickerModule.startImagePicking()
    }
}

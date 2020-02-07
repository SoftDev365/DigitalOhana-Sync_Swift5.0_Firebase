//
//  ViewController.swift
//  SharePhoto
//
//  Created by Admin on 11/5/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import Photos
import HelpCrunchSDK
import MBProgressHUD

class SignInViewController: UIViewController {
    
    @IBOutlet weak var btnGoogleSignIn: UIButton!
    var hud: MBProgressHUD = MBProgressHUD()
    
    var albumPhotos: [PHAsset] = []
    var drivePhotos: [GTLRDrive_File] = []
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.hud)

        // Configure Google Sign In
        GIDSignIn.sharedInstance()?.delegate = self

        // GIDSignIn.sharedInstance()?.signIn() will throw an exception if not set.
        GIDSignIn.sharedInstance()?.uiDelegate = self
        
        GIDSignIn.sharedInstance()?.scopes = [kGTLRAuthScopeDrive, kGTLRAuthScopeDriveFile]
        
        // GIDSignIn.sharedInstance()?.setValue("P5WZ748D57.family-media-sync.SharedItems" forKey: "_keychainName")
        if GIDSignIn.sharedInstance()?.hasAuthInKeychain() == true {
            debugPrint("---- has auth in keychain -----");
            
            self.hud.show(animated: true)

            // Attempt to renew a previously authenticated session without forcing the
            // user to go through the OAuth authentication flow.
            // Will notify GIDSignInDelegate of results via sign(_:didSignInFor:withError:)
            GIDSignIn.sharedInstance()?.signInSilently()
        } else {
            debugPrint("---- no auth in keychain -----");
        }

        /*
        do {
            try Auth.auth().useUserAccessGroup("P5WZ748D57.family-media-sync.SharedItems")
        } catch let error as NSError {
            print("--- Error changing user access group: %@", error)
        }

        Auth.auth().signInAnonymously { (authResult, error) in
            self.activityView.hideActivitiIndicator()
            
            if error != nil {
                // User is signed in
                debugPrint("---- signInAnonymously failed : \(error)-----");
                return
            }
            
            debugPrint("----signInAnonymously complete-----");
            var user = Auth.auth().currentUser
            debugPrint("User is \(user)")
            
            let userid = user!.uid
            // User is signed in
            debugPrint("UserID is \(userid)")

            //self.initRootList()
        }*/
        
        replaceBackButtonToSignout()
        self.navigationController?.isNavigationBarHidden = true
    }
    
    func replaceBackButtonToSignout() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: nil, action: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        replaceBackButtonToSignout()
    }

    @IBAction func onBtnGoogleSiginIn(_ sender: Any) {        
        self.hud.show(animated: true)

        GDModule.defaultFolderID = nil
        Global.setNeedRefresh()

        GIDSignIn.sharedInstance()?.signIn()
    }
    
    func registerUserForShareExtension(userid: String, email: String, username: String) {
        if let userDefaults = UserDefaults(suiteName: "group.io.leruths.ohanasync") {
            userDefaults.set(userid as AnyObject, forKey: "userid")
            userDefaults.set(email as AnyObject, forKey: "email")
            userDefaults.set(username as AnyObject, forKey: "username")
            userDefaults.set(true, forKey: "remember")
            userDefaults.synchronize()
        }
    }
    
    func alertLocalUploadResult(nUpload:Int, nSkip: Int, nFail: Int) {
        let strMsg = Global.getProcessResultMsg(titles: ["Uploaded", "Skipped", "Failed"], counts: [nUpload, nSkip, nFail])
        let alert = UIAlertController(title: strMsg, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.loadDriveFileList()
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    func uploadLocalPhotos() {
        self.hud.show(animated: true)

        SyncModule.uploadSelectedLocalPhotos(assets: self.albumPhotos) { (nUpload, nSkip, nFail) in
            DispatchQueue.main.async() {
                self.alertLocalUploadResult(nUpload: nUpload, nSkip: nSkip, nFail: nFail)
            }
        }
    }
    
    func checkAndUploadLocalPhotos() {
        if self.albumPhotos.count <= 0 {
            self.loadDriveFileList()
            return
        }
        
        self.hud.hide(animated: true)

        let nCount = self.albumPhotos.count
        let strTitle = "There are \(nCount) new photos at Local.\nDo you want to upload them now?"
        let alertController = UIAlertController(title: strTitle, message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Yes", style: .default) { (_) in
            self.uploadLocalPhotos()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.loadDriveFileList()
        }

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func fetchFamilyAlbumPhotos() {
        PHModule.getFamilyAlbumAssets { (result) in
            self.albumPhotos = []
            guard let photoList = result else {
                self.loadDriveFileList()
                return
            }
            
            for index in 0 ..< photoList.count {
                let asset = photoList[index]
                if SyncModule.checkPhotoIsUploaded(localIdentifier: asset.localIdentifier) == false {
                    self.albumPhotos += [asset]
                }
            }
            
            self.checkAndUploadLocalPhotos()
        }
    }
    
    func alertDriveUploadResult(nUpload:Int, nSkip: Int, nFail: Int) {
        let strMsg = Global.getProcessResultMsg(titles: ["Uploaded", "Skipped", "Failed"], counts: [nUpload, nSkip, nFail])
        let alert = UIAlertController(title: strMsg, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.gotoMainVC()
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    func uploadDrivePhotos() {
        self.hud.show(animated: true)

        SyncModule.uploadSelectedDrivePhotos(files: self.drivePhotos) { (nUpload, nSkip, nFail) in
            self.hud.hide(animated: true)
            self.alertDriveUploadResult(nUpload: nUpload, nSkip: nSkip, nFail: nFail)
        }
    }
    
    func checkAndUploadDrivePhotos() {
        if self.drivePhotos.count <= 0 {
            self.hud.hide(animated: true)
            self.gotoMainVC()
            return
        }
        
        self.hud.hide(animated: true)

        let nCount = self.albumPhotos.count
        let strTitle = "There are \(nCount) new photos at Drive.\nDo you want to upload them now?"
        let alertController = UIAlertController(title: strTitle, message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Yes", style: .default) { (_) in
            self.uploadDrivePhotos()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.gotoMainVC()
        }

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func loadDriveFileList() {
        self.hud.show(animated: true)

        GDModule.listFiles() { (fileList) in
            self.drivePhotos = []
            
            if let files = fileList?.files {
                for file in files {
                    if SyncModule.checkPhotoIsUploaded(driveFile: file) == false {
                        self.drivePhotos += [file]
                    }
                }
            }

            self.checkAndUploadDrivePhotos()
        }
    }

    func checkAndAutoUpload() {
        if Global.bAutoUpload == false {
            self.gotoMainVC()
        } else {
            self.hud.show(animated: true)
            GFSModule.getAllPhotos { (success, photoList) in
                self.fetchFamilyAlbumPhotos()
            }
        }
    }
    
    func gotoMainVC() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainVC") as? MainVC {
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func alertNotAllowedUserMessage() {
        let alert = UIAlertController(title: "User not allowed to use this app.", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
        }))
        //alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func waitForAllowingMessage() {
        let alert = UIAlertController(title: "You are registered successfully. Wait for allow by admin.", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
        }))
        //alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func signInWithGoogleUser(_ user: GIDGoogleUser) {
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,                                   accessToken: authentication.accessToken)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if error != nil {
                self.hud.hide(animated: true)
                debugPrint("---- signIn with credential failed-----");
                return
            }
            
            // get registered user info
            GFSModule.getUserInfo(ID: user.userID) { (document) in
                if let data = document?.data() {
                    let allow = data[UserField.allow] as? Bool
                    let displayName = data[UserField.displayname] as? String
                    let bAutoUpload = data[UserField.auto_upload] as? Bool
                    let dateFormatIndex = data[UserField.dateFormatIndex] as? Int

                    if displayName != nil {
                        Global.username = displayName
                    }
                    if bAutoUpload != nil {
                        Global.bAutoUpload = bAutoUpload!
                    } else {
                        Global.bAutoUpload = true
                    }
                    if dateFormatIndex != nil {
                        Global.dtf_index = dateFormatIndex!
                    } else {
                        Global.dtf_index = 0
                    }
                    Global.date_format = Global.dtf_list[Global.dtf_index]

                    if allow == true {
                        self.registerUserForShareExtension(userid: user.userID, email: user.profile.email!, username: user.profile.name)
                        HCModule.updateHelpCrunchUserInfo()
                        self.checkAndAutoUpload()
                    } else {
                        self.alertNotAllowedUserMessage()
                    }
                } else {
                    GFSModule.registerUser()
                    self.waitForAllowingMessage()
                }
                
                self.hud.hide(animated: true)
            }
            
            debugPrint("----Firebase signin complete-----");
        }
    }
}

extension SignInViewController: GIDSignInDelegate, GIDSignInUIDelegate {

    // MARK: - GIDSignInDelegate
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        // sign error
        if error != nil {
            self.hud.hide(animated: true)

            GDModule.service.authorizer = nil
            Global.user = nil
            Global.userid = nil
            Global.username = nil
            Global.email = nil
            return
        }

        // Include authorization headers/values with each Drive API request.
        GDModule.service.authorizer = user.authentication.fetcherAuthorizer()

        Global.user = user
        Global.userid = user.userID
        Global.username = user.profile.name
        Global.origin_name = user.profile.name
        Global.email = user.profile.email

        self.signInWithGoogleUser(user)
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}


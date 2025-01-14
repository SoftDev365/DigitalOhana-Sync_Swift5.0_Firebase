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

class SignInViewController: BaseVC {
    
    @IBOutlet weak var btnGoogleSignIn: UIButton!
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure Google Sign In
        GIDSignIn.sharedInstance()?.delegate = self

        // GIDSignIn.sharedInstance()?.signIn() will throw an exception if not set.
        GIDSignIn.sharedInstance()?.uiDelegate = self
        
        GIDSignIn.sharedInstance()?.scopes = [kGTLRAuthScopeDrive, kGTLRAuthScopeDriveFile]
        
        // GIDSignIn.sharedInstance()?.setValue("P5WZ748D57.family-media-sync.SharedItems" forKey: "_keychainName")
        if GIDSignIn.sharedInstance()?.hasAuthInKeychain() == true {
            debugPrint("---- has auth in keychain -----");

            self.showBusyDialog("Sign In...")

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
        self.showBusyDialog("Sign In...")

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
    
    func gotoMainVC() {
        Global.bNeedToSynchronize = true
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
    
    func gotoMainWith(user: GIDGoogleUser, data:[String: Any]) {
        let allow = data[UserField.allow] as? Bool
        let displayName = data[UserField.displayname] as? String
        let bAutoUpload = data[UserField.auto_upload] as? Bool
        let dateFormatIndex = data[UserField.dateFormatIndex] as? Int
        let timeFormatIndex = data[UserField.timeFormatIndex] as? Int

        if displayName != nil {
            Global.username = displayName
        }
        
        Global.bAutoUpload = bAutoUpload ?? true
        
        Global.date_format_index = dateFormatIndex ?? 0
        Global.date_format = Global.date_format_list[Global.date_format_index]
        
        Global.time_format_index = timeFormatIndex ?? 0
        Global.time_format = Global.time_format_list[Global.time_format_index]

        if allow == true {
            self.registerUserForShareExtension(userid: user.userID, email: user.profile.email!, username: user.profile.name)
            HCModule.updateHelpCrunchUserInfo()
            self.gotoMainVC()
        } else {
            self.alertNotAllowedUserMessage()
        }
    }
    
    func registerNewUser(_ user: GIDGoogleUser) {
        GFSModule.registerUser()
        //self.waitForAllowingMessage()

        Global.bAutoUpload = true
        Global.date_format_index = 0
        Global.date_format = Global.date_format_list[Global.date_format_index]
        Global.time_format_index = 0
        Global.time_format = Global.time_format_list[Global.time_format_index]

        self.registerUserForShareExtension(userid: user.userID, email: user.profile.email!, username: user.profile.name)
        HCModule.updateHelpCrunchUserInfo()
        self.gotoMainVC()
    }
    
    func signInWithGoogleUser(_ user: GIDGoogleUser) {
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,                                   accessToken: authentication.accessToken)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if error != nil {
                self.hideBusyDialog()
                debugPrint("---- signIn with credential failed-----");
                return
            }
            
            // get registered user info
            GFSModule.getUserInfo(ID: user.userID) { (document) in
                self.hideBusyDialog()

                if let data = document?.data() {
                    self.gotoMainWith(user: user, data: data)
                } else {
                    self.registerNewUser(user)
                }
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
            self.hideBusyDialog()

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


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

class SignInViewController: UIViewController {
    
    @IBOutlet weak var btnGoogleSignIn: UIButton!
    let activityView = ActivityView()
    
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
        
        //GIDSignIn.sharedInstance()?.setValue("P5WZ748D57.family-media-sync.SharedItems" forKey: "_keychainName")
        if GIDSignIn.sharedInstance()?.hasAuthInKeychain() == true {
            debugPrint("---- has auth in keychain -----");
            
            activityView.showActivityIndicator(self.view, withTitle: "Sign In...")
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
        
        activityView.showActivityIndicator(self.view, withTitle: "Sign In...")
        
        // init Global parameters
        GDModule.defaultFolderID = nil
        Global.setNeedRefresh()
        // Start Google's OAuth authentication flow
        GIDSignIn.sharedInstance()?.signIn()
        //GIDSignIn.sharedInstance()?.signOut()
    }
    
    func registerUserForShareExtension(userid: String, email: String) {
        if let userDefaults = UserDefaults(suiteName: "group.io.leruths.ohanasync") {
            userDefaults.set(userid as AnyObject, forKey: "userid")
            userDefaults.set(email as AnyObject, forKey: "email")
            userDefaults.set(true, forKey: "remember")
            userDefaults.synchronize()
        }
    }
    
    func initRootList() {
        
        // Safe Present
        //if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NavRootVC") as? NavigationRootVC {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainVC") as? MainVC {
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true, completion: nil)
            //navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension SignInViewController: GIDSignInDelegate, GIDSignInUIDelegate {

    // MARK: - GIDSignInDelegate
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        // A nil error indicates a successful login
        if error == nil {
            // Include authorization headers/values with each Drive API request.
            GDModule.service.authorizer = user.authentication.fetcherAuthorizer()
            
            let email = user!.profile.email
            //Global.user = user
            Global.userid = user!.userID
            Global.username = user!.profile.name
            Global.email = email

            GFSModule.registerUser()

            self.registerUserForShareExtension(userid: user!.userID, email: email!)

            /*
            guard let authentication = user.authentication else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,                                   accessToken: authentication.accessToken)
            Auth.auth().signIn(with: credential) { (authResult, error) in
                //self.activityView.hideActivitiIndicator()
                
                var user = Auth.auth().currentUser
                debugPrint("User is \(user)")
                
                if error != nil {
                    // User is signed in
                    debugPrint("---- signIn with credential failed-----");
                    return
                }
                
                // User is signed in
                debugPrint("----Firebase signin complete-----");
                
                self.initRootList()
            }*/
            
            self.activityView.hideActivitiIndicator()
            self.initRootList()
        } else {
            activityView.hideActivitiIndicator()
            
            GDModule.service.authorizer = nil
            //Global.user = nil
            Global.userid = nil
            Global.username = nil
            Global.email = nil
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}


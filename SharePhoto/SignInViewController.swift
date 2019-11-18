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

        activityView.showActivityIndicator(self.view, withTitle: "Sign In...")
        
        // Attempt to renew a previously authenticated session without forcing the
        // user to go through the OAuth authentication flow.
        // Will notify GIDSignInDelegate of results via sign(_:didSignInFor:withError:)
        GIDSignIn.sharedInstance()?.signInSilently()
        
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
        // Start Google's OAuth authentication flow
        GIDSignIn.sharedInstance()?.signIn()
        //GIDSignIn.sharedInstance()?.signOut()
    }
    
    func initRootList() {
        // Safe Present
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GSExpVC") as? GSExplorerController
        {
            let folderPath = "central"
            vc.setFolderPath(folderPath)            
            navigationController?.pushViewController(vc, animated: true)
        }
        
        /*
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GDExpVC") as? GDExplorerController
        {
            let folderPath = "central"
            vc.setFolderID(folderPath)
            navigationController?.pushViewController(vc, animated: true)
        }*/
    }
    
}

extension SignInViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    // MARK: - GIDSignInDelegate
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        // A nil error indicates a successful login
        if error == nil {
            guard let authentication = user.authentication else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,                                   accessToken: authentication.accessToken)
            
            // Include authorization headers/values with each Drive API request.
            GDModule.service.authorizer = user.authentication.fetcherAuthorizer()
            GDModule.user = user
            
            GSModule.user = user
            
            let auth = user!.authentication
            let email = auth!.value(forKey: "userEmail") as! String
            GSModule.userEmail = email

            Auth.auth().signIn(with: credential) { (authResult, error) in
                if error != nil {
                    return
                }
                
                // User is signed in
                debugPrint("----Firebase signin complete");
                
                self.activityView.hideActivitiIndicator()
                self.initRootList()
            }
            
            //btnGoogleSignIn.isHidden = true
        } else {
            activityView.hideActivitiIndicator()
            
            GDModule.service.authorizer = nil
            GDModule.user = nil
            
            GSModule.user = nil
            GSModule.userEmail = nil
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}


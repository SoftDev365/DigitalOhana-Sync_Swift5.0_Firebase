//
//  ViewController.swift
//  SharePhoto
//
//  Created by Admin on 11/5/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

class SignInViewController: UIViewController {
    
    @IBOutlet weak var btnGoogleSignIn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
                
        // Configure Google Sign In
        GIDSignIn.sharedInstance()?.delegate = self

        // GIDSignIn.sharedInstance()?.signIn() will throw an exception if not set.
        GIDSignIn.sharedInstance()?.uiDelegate = self
        
        GIDSignIn.sharedInstance()?.scopes = [kGTLRAuthScopeDrive, kGTLRAuthScopeDriveFile]

        // Attempt to renew a previously authenticated session without forcing the
        // user to go through the OAuth authentication flow.
        // Will notify GIDSignInDelegate of results via sign(_:didSignInFor:withError:)
        GIDSignIn.sharedInstance()?.signInSilently()
    }

    @IBAction func onBtnGoogleSiginIn(_ sender: Any) {
        // Start Google's OAuth authentication flow
        GIDSignIn.sharedInstance()?.signIn()
        //GIDSignIn.sharedInstance()?.signOut()
    }
    
    func initRootList() {
        // Safe Present
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainVC") as? MainViewController
        {
            //present(vc, animated: true, completion: nil)
            navigationController?.pushViewController(vc, animated: true)
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
            GDModule.user = user
            btnGoogleSignIn.isHidden = true
            
            initRootList()
        } else {
            GDModule.service.authorizer = nil
            GDModule.user = nil
        }
    }
}


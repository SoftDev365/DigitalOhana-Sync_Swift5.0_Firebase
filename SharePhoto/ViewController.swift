//
//  ViewController.swift
//  SharePhoto
//
//  Created by Admin on 11/5/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import GoogleSignIn

class ViewController: UIViewController {
    
    let googleSignInButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.addSubview(googleSignInButton)
        googleSignInButton.setTitle("Google Sign In", for: .normal)
        googleSignInButton.addTarget(self, action: #selector(onGoogleSignInButtonTap), for: .touchUpInside)
        googleSignInButton.frame = CGRect(x: 100, y: 100, width: 200, height: 80)
        
        /***** Configure Google Sign In *****/
        GIDSignIn.sharedInstance()?.delegate = self

        // GIDSignIn.sharedInstance()?.signIn() will throw an exception if not set.
        GIDSignIn.sharedInstance()?.uiDelegate = self
        
        // Attempt to renew a previously authenticated session without forcing the
        // user to go through the OAuth authentication flow.
        // Will notify GIDSignInDelegate of results via sign(_:didSignInFor:withError:)
        GIDSignIn.sharedInstance()?.signInSilently()
    }

    @objc private func onGoogleSignInButtonTap() {
        // Start Google's OAuth authentication flow
        GIDSignIn.sharedInstance()?.signIn()
        //GIDSignIn.sharedInstance()?.signOut()
    }

}

extension ViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    // MARK: - GIDSignInDelegate
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        // A nil error indicates a successful login
        googleSignInButton.isHidden = error == nil
    }
}


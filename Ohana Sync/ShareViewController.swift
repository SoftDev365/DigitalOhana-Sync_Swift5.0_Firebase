//
//  ShareViewController.swift
//  iPhone Family Album
//
//  Created by Admin on 12/9/2020.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import Firebase
import FirebaseStorage
import Photos
import MobileCoreServices

private let reuseIdentifier = "PhotoCell"

class ShareViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout  {
    
    var albumPhotos: [Any]?

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var lblTitle: UILabel!
    
    var autoLogin: Bool = true
    let activityView = ActivityView()

    static var isAlreadyLaunchedOnce = false
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getSharedImages()
    }
    
    func trySignIn() {
        
        if ShareViewController.isAlreadyLaunchedOnce == false {
            // Override point for customization after application launch.
            FirebaseApp.configure()
            
            ShareViewController.isAlreadyLaunchedOnce = true
        }
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID

        // Configure Google Sign In
        GIDSignIn.sharedInstance()?.delegate = self

        // GIDSignIn.sharedInstance()?.signIn() will throw an exception if not set.
        GIDSignIn.sharedInstance()?.uiDelegate = self
        
        GIDSignIn.sharedInstance()?.scopes = [kGTLRAuthScopeDrive, kGTLRAuthScopeDriveFile]
        
        activityView.showActivityIndicator(self.view, withTitle: "Sign In...")
        
        debugPrint("---- use user access group-----");
        
        do {
            try Auth.auth().useUserAccessGroup("P5WZ748D57.family-media-sync.SharedItems")
        } catch let error as NSError {
            print("====Error changing user access group: %@", error)
        }
        
        // Attempt to renew a previously authenticated session without forcing the
        // user to go through the OAuth authentication flow.
        // Will notify GIDSignInDelegate of results via sign(_:didSignInFor:withError:)
        
        //GIDSignIn.sharedInstance()?.signInSilently()
        debugPrint("---- signInAnonymously-----");
        Auth.auth().signInAnonymously { (authResult, error) in
            self.activityView.hideActivitiIndicator()

            var user = Auth.auth().currentUser
            debugPrint("User is \(user)")
            
            if error != nil {
                // User is signed in
                debugPrint("---- signInAnonymously failed-----");
                return
            }

            // User is signed in
            debugPrint("----signInAnonymously complete-----");

            //self.initRootList()
        }
    }

    // Key is the matched asset's original file name without suffix. E.g. IMG_193
    private lazy var imageAssetDictionary: [String : PHAsset] = {
        let options = PHFetchOptions()
        options.includeHiddenAssets = true

        let fetchResult = PHAsset.fetchAssets(with: options)
        var assetDictionary = [String : PHAsset]()

        for i in 0 ..< fetchResult.count {
            let asset = fetchResult[i]
            let fileName = asset.value(forKey: "filename") as! String
            let fileNameWithoutSuffix = fileName.components(separatedBy: ".").first!

            //debugPrint("--- asset name: \(fileNameWithoutSuffix)")
            assetDictionary[fileNameWithoutSuffix] = asset
        }

        return assetDictionary
    }()
    
    func getOneSharedImage(imageItem: NSSecureCoding?, error: Error?) {
        if let image = imageItem as? UIImage {
            // handle UIImage
        } else if let data = imageItem as? NSData {
            // handle NSData
        } else if let url = imageItem as? NSURL {
             // Prefix check: image is shared from Photos app
            if let imageFilePath = url.path, imageFilePath.hasPrefix("/var/mobile/Media/") {
                //debugPrint("==== image file path: \(imageFilePath)")
                
                for component in imageFilePath.components(separatedBy:"/") where component.contains("IMG_") {
                    let fileName = component.components(separatedBy:".").first!
                    //debugPrint("==== share name: \(fileName)")
                    if let asset = imageAssetDictionary[fileName] {
                        //debugPrint("added to list")
                        //self.albumPhotos!.append(asset)
                        self.albumPhotos! += [asset]
                        
                        DispatchQueue.main.async() {
                            self.reloadCollectionView()
                        }
                    } else {
                        //debugPrint("can't find photo named: \(fileName)")
                        //let image = UIImage(contentsOfFile: someURl.path)
                        self.albumPhotos! += [imageFilePath]
                    }
                    
                    break
                }
            }
        }
    }
    
    func getSharedImages() {
        self.albumPhotos = []
        
        let extensionItems = extensionContext?.inputItems as! [NSExtensionItem]

        lblTitle.text = ""
        
        for extensionItem in extensionItems {
            if let itemProviders = extensionItem.attachments {
                lblTitle.text = "\(itemProviders.count) photos are ready to upload"
                
                for itemProvider in itemProviders {
                    if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeJPEG as String) {
                        itemProvider.loadItem(forTypeIdentifier: kUTTypeJPEG as String, options: nil, completionHandler: { data, error in
                            self.getOneSharedImage(imageItem: data, error: error)
                        })
                    } else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypePNG as String) {
                        itemProvider.loadItem(forTypeIdentifier: kUTTypePNG as String, options: nil, completionHandler: { data, error in
                            self.getOneSharedImage(imageItem: data, error: error)
                        })
                    }
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.collectionView.contentInset = UIEdgeInsets.zero
        
        // manually roate to portrait  mode
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.collectionView.collectionViewLayout.invalidateLayout()
        //self.perform(#selector(reloadCollectionView), with: nil, afterDelay: 0.5)
        
        self.trySignIn()
    }
    
    @objc func reloadCollectionView() {
        self.collectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityView.relayoutPosition(self.view)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.albumPhotos?.count ?? 0
    }
    
    func getLocalCell(_ cell: PhotoCell, indexPath: IndexPath) -> UICollectionViewCell {
        guard let photoList = self.albumPhotos else { return cell }

        let photoItem = photoList[indexPath.row]

        if photoItem is PHAsset {
            let asset = photoItem as! PHAsset
            let width = UIScreen.main.scale*cell.frame.size.width
            cell.setLocalAsset(asset, width: width)
            cell.setSelectable(false)
        } else if photoItem is String {
            let filePath = photoItem as! String
            cell.setLocalFile(filePath)
            cell.setSelectable(false)
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCell
        
        return getLocalCell(cell, indexPath: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (self.view.frame.size.width - 10)/3
        return CGSize(width:width, height:width)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5.0
    }

    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5.0
    }

    @IBAction func onBtnUpload(_ sender: Any) {
        
    }
}

extension ShareViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    // MARK: - GIDSignInDelegate
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        // A nil error indicates a successful login
        if error == nil {
            guard let authentication = user.authentication else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,                                   accessToken: authentication.accessToken)
            
            // Include authorization headers/values with each Drive API request.
            GDModule.service.authorizer = user.authentication.fetcherAuthorizer()
            
            let email = user!.profile.email
            Global.user = user
            Global.email = email
     
            GFSModule.registerUser()
            
            //debugPrint("----Firebase auth sign in start-----");
            
            Auth.auth().signIn(with: credential) { (authResult, error) in
                self.activityView.hideActivitiIndicator()

                if error != nil {
                    return
                }
                
                // User is signed in
                debugPrint("----Firebase signin complete-----");
                
                //self.initRootList()
            }
            
            //btnGoogleSignIn.isHidden = true
        } else if self.autoLogin == true {
            self.autoLogin = false
            GIDSignIn.sharedInstance()?.signIn()
            
            debugPrint("----Firebase auto login fail------");
            debugPrint("----Firebase start manual login------");
        } else {
            activityView.hideActivitiIndicator()
            
            GDModule.service.authorizer = nil
            Global.user = nil
            Global.email = nil
            
            debugPrint("----Firebase signin failed-----");
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}


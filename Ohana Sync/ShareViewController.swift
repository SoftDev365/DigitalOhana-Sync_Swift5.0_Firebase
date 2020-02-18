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
import SafariServices

private let reuseIdentifier = "PhotoCell"

class ShareViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout  {
    
    var albumPhotos: [Any]?

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var lblTitle: UILabel!

    var autoLogin: Bool = true
    var bLoggedIn: Bool = false
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
        
        if( SqliteManager.open() ) {
            debugPrint("----db open success------")
        } else {
            debugPrint("----db open fail------")
        }

        accessToPHLibrary()
        
        self.configFirebase()
        self.getSignInUserInfo()
    }
    
    func getSignInUserInfo() {
        if let userDefaults = UserDefaults(suiteName: "group.io.leruths.ohanasync") {

            let bRemember = userDefaults.bool(forKey: "remember")
            let userid = userDefaults.string(forKey: "userid")
            let email = userDefaults.string(forKey: "email")
            let username = userDefaults.string(forKey: "username")
            
            Global.userid = userid
            Global.email = email
            Global.username = username
            
            if bRemember == true {
                self.bLoggedIn = true
            }
            
            //debugPrint("--- sign in remember : \(bRemember), \(userid), \(email), \(username)")
        }
    }
    
    func accessToPHLibrary() {
        let status = PHPhotoLibrary.authorizationStatus()

        if (status == PHAuthorizationStatus.authorized) {
            // Access has been granted.
            self.getSharedImages()
        }
        else if (status == PHAuthorizationStatus.denied) {
            // Access has been denied.
        }
        else if (status == PHAuthorizationStatus.notDetermined) {
            // Access has not been determined.
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                if (newStatus == PHAuthorizationStatus.authorized) {
                    self.performSelector(onMainThread: #selector(self.getSharedImages), with: nil, waitUntilDone: false)
                }
                else {

                }
            })
        }
        else if (status == PHAuthorizationStatus.restricted) {
            // Restricted access - normally won't happen.
        }
    }
    
    func configFirebase() {
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
    }

    func trySignIn() {
        
        if GIDSignIn.sharedInstance()?.hasAuthInKeychain() == true {
            debugPrint("---- has auth in keychain -----")

            activityView.showActivityIndicator(self.view, withTitle: "Sign In...")
            GIDSignIn.sharedInstance()?.signInSilently()
        } else {
            debugPrint("---- no auth in keychain -----")
        }

        /*
        debugPrint("---- use user access group-----")
        
        do {
            try Auth.auth().useUserAccessGroup("P5WZ748D57.family-media-sync.SharedItems")
        } catch let error as NSError {
            print("====Error changing user access group: %@", error)
        }
         
        // Attempt to renew a previously authenticated session without forcing the
        // user to go through the OAuth authentication flow.
        // Will notify GIDSignInDelegate of results via sign(_:didSignInFor:withError:)
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
            
            let email = user!.email
            let userid = user!.uid
            let name = user!.displayName

            // User is signed in
            debugPrint("----signInAnonymously complete-----");

            //self.initRootList()
        }*/
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
        /*
        if let image = imageItem as? UIImage {
            // handle UIImage
        } else if let data = imageItem as? NSData {
            // handle NSData
        } else*/
        if let url = imageItem as? NSURL {
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
    
    @objc func getSharedImages() {
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
            cell.setLocalAsset(asset, width: width, bSync: false)
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
    
    func alertUploadResult(nUpload:Int, nSkip: Int, nFail: Int) {
        let strMsg = Global.getProcessResultMsg(titles: ["Uploaded", "Skipped", "Failed"], counts: [nUpload, nSkip, nFail])
        let alert = UIAlertController(title: strMsg, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            //exit(0)
            self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    func uploadImagePhotos(nUpload: Int, nSkip: Int, nFail: Int) {
        guard let photoList = self.albumPhotos else { return }
        var urlPhotos: [String] = []
        
        for photo in photoList {
            if photo is String {
                let url = photo as! String
                urlPhotos += [url]
            }
        }

        var totalUpload = nUpload
        var totalSkip = nSkip
        var totalFail = nFail
        
        debugPrint("------- start upload local photos --------")
        
        SyncModule.uploadLocalPhotos(files: urlPhotos) { (nUpload, nSkip, nFail) in
            self.activityView.hideActivitiIndicator()
            
            totalUpload += nUpload
            totalSkip += nSkip
            totalFail += nFail
            
            debugPrint("------- done upload local photos --------")
            
            self.alertUploadResult(nUpload: totalUpload, nSkip: totalSkip, nFail: totalFail)
        }
    }
    
    func uploadPHAssetPhotos(albumPhotos: [PHAsset]) {
        debugPrint("---- start upload assets photos--------")
        SyncModule.uploadSelectedLocalPhotos(assets: albumPhotos) { (nUpload, nSkip, nFail) in
            debugPrint("---- end upload assets photos--------")
            self.uploadImagePhotos(nUpload: nUpload, nSkip: nSkip, nFail: nFail)
        }
    }
    
    func moveAssetsToOhanaAlbum(assets: [PHAsset]) {
        guard let album = PHModule.fetchFamilyAlbumCollection() else { return }
        
        debugPrint("---- move to ohana album--------")
        
        PHPhotoLibrary.shared().performChanges({
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            let enumeration = NSMutableArray()
            for asset in assets {
                enumeration.add(asset)
            }
            
            albumChangeRequest?.addAssets(enumeration)
        }, completionHandler: { (success, error) in
            debugPrint("---- done move to ohana album--------")
        })
    }
    
    func uploadPhotos() {
        guard let photoList = self.albumPhotos else { return }

        var assetPhotos: [PHAsset] = []
        
        for photo in photoList {
            if photo is PHAsset {
                let asset = photo as! PHAsset
                assetPhotos += [asset]
            }
        }

        self.activityView.showActivityIndicator(self.view, withTitle: "Uploading...")
        
        if assetPhotos.count > 0 {
            moveAssetsToOhanaAlbum(assets: assetPhotos)
            uploadPHAssetPhotos(albumPhotos: assetPhotos)
        } else {
            uploadImagePhotos(nUpload: 0, nSkip: 0, nFail: 0)
        }
    }
    
    func alertNotSignInMsg() {
        let alert = UIAlertController(title: "Can't login via gmail", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }    

    @IBAction func onBtnUpload(_ sender: Any) {
        if self.bLoggedIn == true {
            self.uploadPhotos()
        } else {
            //GIDSignIn.sharedInstance()?.signIn()
            GIDSignIn.sharedInstance()?.signInSilently()
        }
    }
}

extension ShareViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    // MARK: - GIDSignInDelegate
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        // A nil error indicates a successful login
        if error == nil {
            guard let authentication = user.authentication else { return }
            
            // Include authorization headers/values with each Drive API request.
            GDModule.service.authorizer = authentication.fetcherAuthorizer()
            
            let email = user!.profile.email
            Global.user = user
            Global.userid = user!.userID
            Global.username = user!.profile.name
            Global.email = email
     
            GFSModule.registerUser()
            
            //debugPrint("----Firebase auth sign in start-----");
            /*
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,                                   accessToken: authentication.accessToken)
            Auth.auth().signIn(with: credential) { (authResult, error) in
                self.activityView.hideActivitiIndicator()

                if error != nil {
                    return
                }
                
                // User is signed in
                debugPrint("----Firebase signin complete-----");
                
                //self.initRootList()
            }*/
            //btnGoogleSignIn.isHidden = true
            
            self.activityView.hideActivitiIndicator()
            
            self.uploadPhotos()
            
        } else if self.autoLogin == true {
            self.autoLogin = false
            GIDSignIn.sharedInstance()?.signIn()
  
            debugPrint("----Firebase auto login fail------");
            debugPrint("----Firebase start manual login------");
        } else {
            activityView.hideActivitiIndicator()
            
            GDModule.service.authorizer = nil
            Global.user = nil
            Global.userid = nil
            Global.email = nil
            
            debugPrint("----Firebase signin failed-----");
            
            self.alertNotSignInMsg()
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}


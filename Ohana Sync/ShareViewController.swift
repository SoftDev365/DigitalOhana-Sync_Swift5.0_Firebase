//
//  LocalAlbumVC.swift
//  iPhone Family Album
//
//  Created by Admin on 11/22/19.
//  Copyright © 2019 Admin. All rights reserved.
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
    let activityView = ActivityView()

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
                debugPrint("==== image file path: \(imageFilePath)")
                
                for component in imageFilePath.components(separatedBy:"/") where component.contains("IMG_") {
                    let fileName = component.components(separatedBy:".").first!
                    debugPrint("==== share name: \(fileName)")
                    if let asset = imageAssetDictionary[fileName] {
                        debugPrint("added to list")
                        //self.albumPhotos!.append(asset)
                        self.albumPhotos! += [asset]
                        
                        DispatchQueue.main.async() {
                            self.reloadCollectionView()
                        }
                    } else {
                        debugPrint("can't find photo named: \(fileName)")
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

        for extensionItem in extensionItems {
            if let itemProviders = extensionItem.attachments {
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

    @IBAction func onBtnDone(_ sender: Any) {
        
    }
}

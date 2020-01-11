//
//  ShareViewController.swift
//  Ohana Sync
//
//  Created by Admin on 1/10/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices

class OrgViewController: UIViewController {
    @IBOutlet weak var imgView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        let extensionItems = extensionContext?.inputItems as! [NSExtensionItem]

        for extensionItem in extensionItems {
            if let itemProviders = extensionItem.attachments {
                for itemProvider in itemProviders {
                    if itemProvider.hasItemConformingToTypeIdentifier(kUTTypePNG as String) {
                        itemProvider.loadItem(forTypeIdentifier: kUTTypePNG as String, options: nil, completionHandler: { text, error in
                            let alert = UIAlertController(title: "Alarm", message: "Here is ShareViewController", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
                                (a) -> Void in
                                let board = UIStoryboard(name: "MainInterface", bundle: nil)
                                self.present(board.instantiateViewController(withIdentifier: "abc"), animated: true, completion: nil)
                            }))
                            self.present(alert, animated: true, completion: nil)
                        })
                    } else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeJPEG as String) {
                        itemProvider.loadItem(forTypeIdentifier: kUTTypeJPEG as String, options: nil, completionHandler: { data, error in
                            var image: UIImage?
                            if let someURl = data as? URL {
                                image = UIImage(contentsOfFile: someURl.path)
                            } else if let someImage = data as? UIImage {
                                image = someImage
                            }

                            if let someImage = image {
                                self.imgView.image = someImage
                            }
                        })
                    }
                }
            }
        }*/
    }
}

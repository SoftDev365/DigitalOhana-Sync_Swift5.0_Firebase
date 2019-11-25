//
//  ImagePickerModule.swift
//  SharePhoto
//
//  Created by Admin on 11/26/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit

protocol ImagePickerModuleDelegate {
    func imagePickerModule(_ module: ImagePickerModule, completeWithImage image:UIImage)
}

class ImagePickerModule: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var viewController: UIViewController!
    var imagePicker = UIImagePickerController()
    var delegate: ImagePickerModuleDelegate?
    
    init(_ viewController: UIViewController) {
        super.init()
            
        self.viewController = viewController
    }
    
    func startImagePicking() {
        self.chooseImagePickerSource()
    }

    internal func chooseImagePickerSource() {
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))

        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallary()
        }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        self.viewController.present(alert, animated: true, completion: nil)
    }
    
    internal func openCamera() {
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.viewController.present(imagePicker, animated: true, completion: nil)
        }
        else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.viewController.present(alert, animated: true, completion: nil)
        }
    }

    internal func openGallary() {
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .fullScreen

        self.viewController.present(imagePicker, animated: true, completion: nil)
    }
    
    internal func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
        }
    }

    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        guard let delegate = self.delegate else {
            return
        }

        let imagePhoto: UIImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        delegate.imagePickerModule(self, completeWithImage: imagePhoto)
    }
}

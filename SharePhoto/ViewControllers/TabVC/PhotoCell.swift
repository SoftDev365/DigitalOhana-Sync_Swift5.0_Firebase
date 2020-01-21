//
//  PhotoCell.swift
//  SharePhoto
//
//  Created by Admin on 12/20/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import Photos
import GoogleAPIClientForREST

class PhotoCell: UICollectionViewCell {
    enum PhotoCellType: Int {
        case local = 0
        case drive = 1
        case cloud = 2
        case frame = 3
    }
    
    let tagPHOTO = 1
    let tagCHECKBOX = 2
    //let tagLABEL = 3

    var type: PhotoCellType!
    var fileID: String? = nil
    let cloudFolderPath = "central"
    
    var localAsset: PHAsset?
    var driveFile: GTLRDrive_File?

    var ivPhoto: UIImageView?
    var ivChkBox: UIImageView?
    var checked: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        ivPhoto = self.viewWithTag(tagPHOTO) as? UIImageView
        ivChkBox = self.viewWithTag(tagCHECKBOX) as? UIImageView
    }
    
    open func setEmpty() {
        self.ivPhoto?.image = UIImage(named: "nophoto")
        self.fileID = ""
        self.localAsset = nil
    }

    open func setPaddingToPhoto(_ size: CGFloat) {
        for constraint in self.contentView.constraints {
            if constraint.identifier == "left_padding" {
               constraint.constant = size
            }
            if constraint.identifier == "right_padding" {
               constraint.constant = size
            }
            if constraint.identifier == "top_padding" {
               constraint.constant = size
            }
            if constraint.identifier == "bottom_padding" {
               constraint.constant = size
            }
        }

        self.layoutIfNeeded()
    }
    
    open func setPaddingToPhoto(_ size: CGFloat, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.setPaddingToPhoto(size)
            }) { (success) in
            }
        } else {
            setPaddingToPhoto(size)
        }
    }
    
    open func isChecked() -> Bool {
        return self.checked
    }
    
    open func setSelectable(_ selectable: Bool) {
        if selectable {
            ivChkBox?.isHidden = false
        } else {
            ivChkBox?.isHidden = true
            setPaddingToPhoto(0, animated: false)
        }
    }
    
    open func reverseCheckStatus() {
        setChecked(!self.checked)
    }
    
    open func setPreviousStatus(_ checked: Bool) {
        if checked {
            setPaddingToPhoto(10, animated: false)
        } else {

            setPaddingToPhoto(0, animated: false)
        }
    }

    open func setChecked(_ checked: Bool) {
        self.checked = checked

        if checked {
            ivChkBox?.image = UIImage(named: "checkbox_d")
            setPaddingToPhoto(10, animated: true)
        } else {
            ivChkBox?.image = UIImage(named: "checkbox_n")
            setPaddingToPhoto(0, animated: true)
        }
    }

    open func setCheckboxStatus(_ bShow: Bool, checked: Bool) {
        if bShow == false {
            ivChkBox?.isHidden = true
            setPaddingToPhoto(0, animated: false)
        } else {
            ivChkBox?.isHidden = false
            setChecked(checked)
        }
    }
    
    open func setCloudFile(_ fileID: String) {
        self.setEmpty()
        
        self.type = .cloud
        self.fileID = fileID

        let thumbFileID = GSModule.getThumbnailFileID(cloudFileID: fileID)
        
        GSModule.downloadImageFile(cloudFileID: thumbFileID, folderPath: self.cloudFolderPath, onCompleted: { (fileID, image) in
            // if cell point still the same photo (cell may be changed to the other while downloading)
            if thumbFileID == fileID {
                self.ivPhoto?.image = image
            }
            //if SyncModule.checkPhotoIsDownloaded(fileID: self.filePath) == false {
                //btnDownload.isHidden = false
            //}
        })
    }
    
    open func setLocalFile(_ imgPath: String) {
        self.setEmpty()

        if let image = UIImage(contentsOfFile: imgPath) {
            self.ivPhoto?.image = image
        }
    }
    
    open func setLocalAsset(_ asset: PHAsset, width:CGFloat) {
        self.setEmpty()
        
        let size = CGSize(width:width, height:width)
        self.type = .local
        self.localAsset = asset

        PHCachingImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil) { (image, info) in
            // skip twice calls
            //let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            //if isDegraded {
            //   return
            //}
            self.ivPhoto?.image = image
        }
    }
    
    open func setDriveFile(_ file: GTLRDrive_File) {
        self.setEmpty()
        
        self.type = .drive
        self.driveFile = file
        
        if let thumnailLink = file.thumbnailLink {
            self.ivPhoto?.loadImageUsingCache(withUrl: thumnailLink)
        } else {
            GDModule.downloadImage(fileID: file.identifier!) { (fileID, image) in
                if self.driveFile!.identifier == fileID {
                    self.ivPhoto?.image = image
                }
            }
        }
    }
    
    func refreshView() {
        
    }
}

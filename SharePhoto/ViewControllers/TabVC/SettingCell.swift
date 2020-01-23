//
//  SettingCell.swift
//  SharePhoto
//
//  Created by Admin on 1/23/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit
import Photos
import GoogleAPIClientForREST

class SettingCell: UITableViewCell {

    @IBOutlet weak var viewIcon: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var viewBadge: UIView!
    @IBOutlet weak var lblBadge: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        viewBadge.layer.cornerRadius = viewBadge.frame.height/2
        viewBadge.layer.masksToBounds = true
        viewBadge.isHidden = true
    }

    func setIcon(image: UIImage?) {
        viewIcon.image = image
    }
    
    func setLabel(title: String) {
        lblTitle.text = title
    }
    
    func setBadgeNumber(number: Int) {
        if number == 0 {
            viewBadge.isHidden = true
        } else {
            viewBadge.isHidden = false
            lblBadge.text = "\(number)"
        }
    }
}

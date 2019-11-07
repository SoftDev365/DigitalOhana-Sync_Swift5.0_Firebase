//
//  FileTableViewCell.swift
//  SharePhoto
//
//  Created by Admin on 11/7/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit

class FileTableViewCell: UITableViewCell {

    @IBOutlet weak var imgThumb: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

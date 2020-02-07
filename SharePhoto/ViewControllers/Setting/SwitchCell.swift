//
//  SwitchCell.swift
//  SharePhoto
//
//  Created by Admin on 2/5/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit

protocol SwitchCellDelegate: AnyObject {
    func switchCell(_ cell: SwitchCell, changedOnOff isOn: Bool)
}

class SwitchCell: UITableViewCell {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var swcOnOff: UISwitch!
    
    var delegate: SwitchCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func onSwitchOnOff() {
        self.delegate?.switchCell(self, changedOnOff: swcOnOff.isOn)
    }
}

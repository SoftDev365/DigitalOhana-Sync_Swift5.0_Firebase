//
//  DatePickerVC.swift
//  SharePhoto
//
//  Created by Admin on 1/28/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit

class DatePickerVC: UIViewController {
    
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnConfirm: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewContent.layer.cornerRadius = 10
        viewContent.layer.masksToBounds = true
        viewContent.layer.borderWidth = 1
        viewContent.layer.borderColor = UIColor.lightGray.cgColor
        
        btnConfirm.layer.borderWidth = 1
        btnConfirm.layer.borderColor = UIColor.lightGray.cgColor
        btnCancel.layer.borderWidth = 1
        btnCancel.layer.borderColor = UIColor.lightGray.cgColor
    }

    @IBAction func onBtnConfirm(_ sender: Any) {
        self.view.removeFromSuperview()
    }
    
    @IBAction func onBtnCancel(_ sender: Any) {
        self.view.removeFromSuperview()
    }
}

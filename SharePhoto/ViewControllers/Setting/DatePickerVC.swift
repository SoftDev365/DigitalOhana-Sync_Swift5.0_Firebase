//
//  DatePickerVC.swift
//  SharePhoto
//
//  Created by Admin on 1/28/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit

protocol DatePickerVCDelegate: AnyObject {
    func didChooseDate(date: Date, ofTag tag: Int)
}

class DatePickerVC: UIViewController {
    
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnConfirm: UIButton!
    
    var tag: Int = 0
    var delegate: DatePickerVCDelegate? = nil
    
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
    
    func setDate(timeInterval: TimeInterval) {
        let date = Date(timeIntervalSince1970: timeInterval)
        datePicker.setDate(date, animated: true)
    }

    @IBAction func onBtnConfirm(_ sender: Any) {
        let date = datePicker.date
        self.delegate?.didChooseDate(date: date, ofTag: self.tag)
        
        self.view.removeFromSuperview()
    }
    
    @IBAction func onBtnCancel(_ sender: Any) {
        self.view.removeFromSuperview()
    }
}

//
//  SearchFieldVC.swift
//  SharePhoto
//
//  Created by Admin on 1/28/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit

protocol SearchFieldVCDelegate: AnyObject {
    func didClickOnSearchButton()
}

class SearchFieldVC: UIViewController, DatePickerVCDelegate, UserListVCDelegate {

    @IBOutlet weak var swcTaken: UISwitch!
    @IBOutlet weak var swcUpload: UISwitch!
    @IBOutlet weak var swcUser: UISwitch!
    
    @IBOutlet weak var btnTakenFrom: UIButton!
    @IBOutlet weak var btnTakenTo: UIButton!
    
    @IBOutlet weak var btnUploadFrom: UIButton!
    @IBOutlet weak var btnUploadTo: UIButton!
    
    @IBOutlet weak var btnUserName: UIButton!
    
    @IBOutlet weak var viewTaken: UIView!
    @IBOutlet weak var viewUpload: UIView!
    @IBOutlet weak var viewUser: UIView!
    
    var delegate: SearchFieldVCDelegate?
    var datePickerVC: DatePickerVC!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViewBorder(view: viewTaken)
        self.initViewBorder(view: viewUpload)
        self.initViewBorder(view: viewUser)
        
        self.datePickerVC = (UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DatePickerVC") as! DatePickerVC)
        self.addChild(self.datePickerVC)
        self.datePickerVC.delegate = self
        
        self.navigationController?.title = "Search Options"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.initFileds()
        self.refreshDateButtonStatus()
    }

    func initViewBorder(view: UIView) {
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    func initFileds() {
        let options = Global.searchOption
        
        swcTaken.isOn = options.bTakenDate
        swcUpload.isOn = options.bUploadDate
        swcUser.isOn = options.bUserName

        let curDate = Date()
        var dateComponents = DateComponents()
        dateComponents.month = -1
        dateComponents.day = 0
        dateComponents.year = 0
        let monthAgo = Calendar.current.date(byAdding:dateComponents, to: curDate)
        
        if options.takenDateFrom == nil {
            options.takenDateFrom = monthAgo?.timeIntervalSince1970
        }
        if options.takenDateTo == nil {
            options.takenDateTo = curDate.timeIntervalSince1970
        }
        
        if options.uploadDateFrom == nil {
            options.uploadDateFrom = monthAgo?.timeIntervalSince1970
        }
        if options.uploadDateTo == nil {
            options.uploadDateTo = curDate.timeIntervalSince1970
        }
        
        self.refreshButtonValues()
    }
    
    func refreshButtonValues() {
        let options = Global.searchOption
        
        self.setLabel(button: btnTakenFrom, timeInterval: options.takenDateFrom)
        self.setLabel(button: btnTakenTo, timeInterval: options.takenDateTo)
        self.setLabel(button: btnUploadFrom, timeInterval: options.uploadDateFrom)
        self.setLabel(button: btnUploadTo, timeInterval: options.uploadDateTo)
        
        if options.userName == nil || options.userName == "" {
            btnUserName.setTitle("All", for: .normal)
        } else {
            btnUserName.setTitle(options.userName, for: .normal)
        }
    }
    
    func setLabel(button: UIButton, timeInterval: TimeInterval?) {
        var date = Date()
        
        if timeInterval != nil {
            date = Date(timeIntervalSince1970: timeInterval!)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let strDate = formatter.string(from: date)

        button.setTitle(strDate, for: .normal)
    }
    
    func refreshDateButtonStatus() {
        let options = Global.searchOption

        btnTakenFrom.isEnabled = options.bTakenDate
        btnTakenTo.isEnabled = options.bTakenDate
        
        btnUploadFrom.isEnabled = options.bUploadDate
        btnUploadTo.isEnabled = options.bUploadDate
        
        btnUserName.isEnabled = options.bUserName
    }
    
    func showDatePickerView(date: TimeInterval, ofTag tag: Int) {
        self.view.addSubview(self.datePickerVC.view)
        self.datePickerVC.view.frame = self.view.bounds
        
        self.datePickerVC.setDate(timeInterval: date)
        self.datePickerVC.tag = tag
    }

    @IBAction func onSwitchTaken(_ sender: Any) {
        Global.searchOption.bTakenDate = swcTaken.isOn
        refreshDateButtonStatus()
    }
    
    @IBAction func onBtnTakenFrom(_ sender: Any) {
        let options = Global.searchOption
        showDatePickerView(date: options.takenDateFrom!, ofTag: 1)
    }
    
    @IBAction func onBtnTakenTo(_ sender: Any) {
        let options = Global.searchOption
        showDatePickerView(date: options.takenDateTo!, ofTag: 2)
    }
    
    @IBAction func onSwitchUpload(_ sender: Any) {
        Global.searchOption.bUploadDate = swcUpload.isOn
        refreshDateButtonStatus()
    }
    
    @IBAction func onBtnUploadFrom(_ sender: Any) {
        let options = Global.searchOption
        showDatePickerView(date: options.uploadDateFrom!, ofTag: 3)
    }
    
    @IBAction func onBtnUploadTo(_ sender: Any) {
        let options = Global.searchOption
        showDatePickerView(date: options.uploadDateTo!, ofTag: 4)
    }
    
    @IBAction func switchUser(_ sender: Any) {
        Global.searchOption.bUserName = swcUser.isOn
        refreshDateButtonStatus()
    }
    
    @IBAction func onBtnUserName(_ sender: Any) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserListVC") as? UserListVC {
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func onBtnSearch(_ sender: Any) {
        self.delegate?.didClickOnSearchButton()

        self.navigationController?.popViewController(animated: true)
    }
    
    func didChooseDate(date: Date, ofTag tag: Int) {
        if tag == 1 {
            Global.searchOption.takenDateFrom = date.timeIntervalSince1970
        } else if tag == 2 {
            Global.searchOption.takenDateTo = date.timeIntervalSince1970
        } else if tag == 3 {
            Global.searchOption.uploadDateFrom = date.timeIntervalSince1970
        } else if tag == 4 {
            Global.searchOption.uploadDateTo = date.timeIntervalSince1970
        }

        self.refreshButtonValues()
    }
    
    func didChooseUser(id: String, email: String, name: String) {
        Global.searchOption.userid = id
        Global.searchOption.userName = name
        Global.searchOption.email = email
        
        self.refreshButtonValues()
    }
}

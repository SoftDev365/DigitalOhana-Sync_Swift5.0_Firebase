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
    
    var tempOption: SearchOption = SearchOption()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViewBorder(view: viewTaken)
        self.initViewBorder(view: viewUpload)
        self.initViewBorder(view: viewUser)
        
        self.datePickerVC = (UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DatePickerVC") as! DatePickerVC)
        self.addChild(self.datePickerVC)
        self.datePickerVC.delegate = self
        
        self.title = "Search Options"
        self.tempOption = Global.searchOption.copy()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.initFileds()
        self.refreshButtonStatus()
    }

    func initViewBorder(view: UIView) {
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    func initFileds() {
        let options = self.tempOption
        
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
        let options = self.tempOption
        
        self.setLabel(button: btnTakenFrom, timeInterval: options.takenDateFrom)
        self.setLabel(button: btnTakenTo, timeInterval: options.takenDateTo)
        self.setLabel(button: btnUploadFrom, timeInterval: options.uploadDateFrom)
        self.setLabel(button: btnUploadTo, timeInterval: options.uploadDateTo)
        
        if options.userName == nil || options.userName == "" {
            btnUserName.setTitle("Everyone", for: .normal)
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
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let strDate = formatter.string(from: date)

        button.setTitle(strDate, for: .normal)
    }
    
    func refreshButtonStatus() {
        let options = self.tempOption

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
        self.tempOption.bTakenDate = swcTaken.isOn
        refreshButtonStatus()
    }
    
    @IBAction func onBtnTakenFrom(_ sender: Any) {
        let options = self.tempOption
        showDatePickerView(date: options.takenDateFrom!, ofTag: 1)
    }
    
    @IBAction func onBtnTakenTo(_ sender: Any) {
        let options = self.tempOption
        showDatePickerView(date: options.takenDateTo!, ofTag: 2)
    }
    
    @IBAction func onSwitchUpload(_ sender: Any) {
        self.tempOption.bUploadDate = swcUpload.isOn
        refreshButtonStatus()
    }
    
    @IBAction func onBtnUploadFrom(_ sender: Any) {
        let options = self.tempOption
        showDatePickerView(date: options.uploadDateFrom!, ofTag: 3)
    }
    
    @IBAction func onBtnUploadTo(_ sender: Any) {
        let options = self.tempOption
        showDatePickerView(date: options.uploadDateTo!, ofTag: 4)
    }
    
    @IBAction func switchUser(_ sender: Any) {
        self.tempOption.bUserName = swcUser.isOn
        
        if swcUser.isOn == false {
            self.tempOption.userid = nil
            self.tempOption.userName = nil
            self.tempOption.email = nil
        }
        
        refreshButtonStatus()
        refreshButtonValues()
    }
    
    @IBAction func onBtnUserName(_ sender: Any) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserListVC") as? UserListVC {
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func onBtnSearch(_ sender: Any) {
        Global.searchOption = self.tempOption
        
        let options = Global.searchOption
        
        options.takenDateFrom = Global.getDateStartInterval(interval: options.takenDateFrom)
        options.takenDateTo = Global.getDateEndInterval(interval: options.takenDateTo)
        options.uploadDateFrom = Global.getDateStartInterval(interval: options.uploadDateFrom)
        options.uploadDateTo = Global.getDateEndInterval(interval: options.uploadDateTo)

        self.navigationController?.popViewController(animated: true)
        
        self.delegate?.didClickOnSearchButton()
    }
    
    func didChooseDate(date: Date, ofTag tag: Int) {
        if tag == 1 {
            self.tempOption.takenDateFrom = date.timeIntervalSince1970
        } else if tag == 2 {
            self.tempOption.takenDateTo = date.timeIntervalSince1970
        } else if tag == 3 {
            self.tempOption.uploadDateFrom = date.timeIntervalSince1970
        } else if tag == 4 {
            self.tempOption.uploadDateTo = date.timeIntervalSince1970
        }

        self.refreshButtonValues()
    }
    
    func didChooseUser(id: String, email: String, name: String) {
        self.tempOption.userid = id
        self.tempOption.userName = name
        self.tempOption.email = email
        
        self.refreshButtonValues()
    }
}

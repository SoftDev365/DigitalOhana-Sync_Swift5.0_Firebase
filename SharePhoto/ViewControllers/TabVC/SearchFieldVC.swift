//
//  SearchFieldVC.swift
//  SharePhoto
//
//  Created by Admin on 1/28/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit

class SearchFieldVC: UIViewController {

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
    
    var datePickerVC: DatePickerVC!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initViewBorder(view: viewTaken)
        self.initViewBorder(view: viewUpload)
        self.initViewBorder(view: viewUser)
        
        self.datePickerVC = (UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DatePickerVC") as! DatePickerVC)
        self.addChild(self.datePickerVC)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.initFileds()
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
        
        self.setLabel(button: btnTakenFrom, timeInterval: options.takenDateFrom)
        self.setLabel(button: btnTakenTo, timeInterval: options.takenDateTo)
        self.setLabel(button: btnUploadFrom, timeInterval: options.uploadDateFrom)
        self.setLabel(button: btnUploadTo, timeInterval: options.uploadDateTo)
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

    @IBAction func onSwitchTaken(_ sender: Any) {
    }
    
    @IBAction func onBtnTakenFrom(_ sender: Any) {
        self.view.addSubview(self.datePickerVC.view)
        self.datePickerVC.view.frame = self.view.bounds
    }
    
    @IBAction func onBtnTakenTo(_ sender: Any) {
        self.view.addSubview(self.datePickerVC.view)
        self.datePickerVC.view.frame = self.view.bounds
    }
    
    @IBAction func onSwitchUpload(_ sender: Any) {
    }
    
    @IBAction func onBtnUploadFrom(_ sender: Any) {
    }
    
    @IBAction func onBtnUploadTo(_ sender: Any) {
    }
    
    @IBAction func switchUser(_ sender: Any) {
    }
    
    @IBAction func onBtnUserName(_ sender: Any) {
    }
    
    @IBAction func onBtnSearch(_ sender: Any) {
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

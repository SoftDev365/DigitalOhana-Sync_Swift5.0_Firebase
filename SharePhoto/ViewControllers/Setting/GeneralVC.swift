//
//  GeneralVC.swift
//  SharePhoto
//
//  Created by Admin on 2/5/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit
import MessageUI
import MBProgressHUD

class GeneralVC: UIViewController, UITableViewDataSource, UITableViewDelegate, SwitchCellDelegate, MFMailComposeViewControllerDelegate  {

    @IBOutlet weak var tableView: UITableView!
    var hud: MBProgressHUD = MBProgressHUD()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.title = "General"
        self.view.addSubview(hud)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        self.tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")

        if indexPath.row == 0 {
            cell.textLabel?.text = "Display Name"
            cell.detailTextLabel?.text = Global.username
        } else if indexPath.row == 1 {
            cell.textLabel?.text = "Date Format"
            cell.detailTextLabel?.text = Global.date_format?.uppercased()
            cell.accessoryType = .disclosureIndicator
        } else if indexPath.row == 2 {
            cell.textLabel?.text = "Time Format"
            cell.detailTextLabel?.text = Global.time_format?.uppercased()
            cell.accessoryType = .disclosureIndicator
        } else if indexPath.row == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
            cell.delegate = self
            cell.swcOnOff.isOn = Global.bAutoUpload
            return cell
        } else if indexPath.row == 4 {
            cell.textLabel?.text = "Invite"
            cell.detailTextLabel?.text = "Send email to friend"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.inputDisplayName()
        } else if indexPath.row == 1 {
            self.showDateFormatListVC(true)
        } else if indexPath.row == 2 {
            self.showDateFormatListVC(false)
        } else if indexPath.row == 4 {
            self.sendInviteEmail()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func inputDisplayName() {
        let alertController = UIAlertController(title: "Edit display name", message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Edit", style: .default) { (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                self.updateUser(displayName: text)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        alertController.addTextField { (textField) in
            textField.text = Global.username
            textField.placeholder = "Display name"
        }

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func alertEditNameFailed() {
        let alertController = UIAlertController(title: "Edit name failed. May be due to Internet Connection!", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel) { (_) in }
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func updateUser(displayName: String) {
        hud.show(animated: true)

        GFSModule.updateUser(displayName: displayName) { (success) in
            self.hud.hide(animated: true)
            
            if success {
                Global.username = displayName
                HCModule.updateHelpCrunchUserInfo()
                self.tableView.reloadData()
            } else {
                self.alertEditNameFailed()
            }
        }
    }
    
    func showDateFormatListVC(_ bDateFormat: Bool) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DateFormatListVC") as? DateFormatListVC {
            if bDateFormat {
                vc.set(viewMode: .dateFormat)
            } else {
                vc.set(viewMode: .timeFormat)
            }
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func alertChangeAutoUploadFailed() {
        let alertController = UIAlertController(title: "Changing AutoUpload setting failed. May be due to Internet Connection!", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel) { (_) in }
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func switchCell(_ cell: SwitchCell, changedOnOff isOn: Bool) {
        hud.show(animated: true)
        
        GFSModule.updateUser(autoUpload: isOn) { (success) in
            self.hud.hide(animated: true)
            
            if success {
                
            } else {
                self.alertChangeAutoUploadFailed()
                self.tableView.reloadData()
            }
        }
    }
    
    func sendInviteEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([])
            mail.setMessageBody("<p>You can access to the testflight app from the follwing link!<br>https://testflight.apple.com/join/E7QR6QEl</p>", isHTML: true)

            present(mail, animated: true)
        } else {
            // show failure alert
            let alertController = UIAlertController(title: "Can't send email.\nConfigure your email first.", message: nil, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel) { (_) in }
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

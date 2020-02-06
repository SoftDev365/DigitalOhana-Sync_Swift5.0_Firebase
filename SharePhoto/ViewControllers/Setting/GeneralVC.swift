//
//  GeneralVC.swift
//  SharePhoto
//
//  Created by Admin on 2/5/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit
import MessageUI

class GeneralVC: UIViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate  {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.title = "General"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")

        if indexPath.row == 0 {
            cell.textLabel?.text = "Display Name"
            cell.detailTextLabel?.text = Global.username
        } else if indexPath.row == 1 {
            cell.textLabel?.text = "DateTime Format"
            cell.detailTextLabel?.text = "MM/DD/YYYY"
        } else if indexPath.row == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath)
            return cell
        } else if indexPath.row == 3 {
            cell.textLabel?.text = "Invite"
            cell.detailTextLabel?.text = "Send email to friend"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.inputDisplayName()
        } else if indexPath.row == 1 {
            self.showDateFormatListVC()
        } else if indexPath.row == 3 {
            self.sendInviteEmail()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func inputDisplayName() {
        let alertController = UIAlertController(title: "Edit display name", message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Edit", style: .default) { (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                self.updateDisplayName(text)
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
    
    func updateDisplayName(_ text: String) {
        Global.username = text
    }
    
    func showDateFormatListVC() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DateFormatListVC") as? DateFormatListVC {
            navigationController?.pushViewController(vc, animated: true)
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

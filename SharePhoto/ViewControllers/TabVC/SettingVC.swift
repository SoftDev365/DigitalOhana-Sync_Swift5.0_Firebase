//
//  LocalAlbumVC.swift
//  iPhone Family Album
//
//  Created by Admin on 11/22/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import Firebase
import FirebaseStorage
import Photos
import HelpCrunchSDK

class SettingVC : UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(numberOfUnreadMessagesChanged), name: NSNotification.Name.HCSUnreadMessages, object: nil)
    }
        
    @objc func numberOfUnreadMessagesChanged() {
        let messages = Int(HelpCrunch.numberOfUnreadMessages())
        let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! SettingCell
        
        cell.setBadgeNumber(number: messages)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 2 {
            let view = UIView()
            view.backgroundColor = .clear
        
            return view
        }

        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 2 {
            return tableView.frame.height - 230
        }
        
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SettingCell

        if indexPath.section == 0 {
            cell.setIcon(image: UIImage(systemName: "gear"))
            cell.setLabel(title: "General")
            cell.setBadgeNumber(number: 0)
            cell.accessoryType = .disclosureIndicator
        } else if indexPath.section == 1 {
            cell.setIcon(image: UIImage(systemName: "questionmark.circle"))
            cell.setLabel(title: "Help")
            
            let messages = Int(HelpCrunch.numberOfUnreadMessages())
            cell.setBadgeNumber(number: messages)
        } else {
            cell.setIcon(image: UIImage(systemName: "arrow.uturn.left.square"))
            cell.setLabel(title: "Sign Out")
            cell.setBadgeNumber(number: 0)
        }
        
        return cell
    }
    
    func showHelpCrunch() {
        HelpCrunch.show(from: self) { (error) in
            // If you need to do something on completion of SDK view controller presenting
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            self.showHelpCrunch()
        } else if indexPath.section == 2 {
            self.logout()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func logout() {
        MainVC.sharedMainVC?.doLogout()
    }
}

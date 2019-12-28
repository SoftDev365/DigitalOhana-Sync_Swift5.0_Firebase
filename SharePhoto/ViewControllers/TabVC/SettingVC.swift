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

class SettingVC : UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")

        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.imageView?.image = UIImage(named: "icon_setting")
                cell.textLabel?.text = "General"
            } else {
                cell.imageView?.image = UIImage(named: "icon_alarm")
                cell.textLabel?.text = "Notifications"
            }
            
            cell.accessoryType = .disclosureIndicator
        } else if indexPath.section == 1 {
            cell.imageView?.image = UIImage(named: "icon_home")
            cell.textLabel?.text = "Contact"
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.textLabel?.text = "Sign out"
            if #available(iOS 13.0, *) {
                cell.imageView?.image = UIImage(systemName: "person.fill")
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            self.logout()
        }
    }
    
    func logout() {
        MainVC.sharedMainVC?.doLogout()
    }
}

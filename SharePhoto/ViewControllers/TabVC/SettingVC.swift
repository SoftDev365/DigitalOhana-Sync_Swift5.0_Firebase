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
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 3 {
            let view = UIView()
            view.backgroundColor = .clear
        
            return view
        }
        
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 3 {
            return tableView.frame.height - 270
        }
        
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")

        if indexPath.section == 0 {
                cell.imageView?.image = UIImage(named: "icon_setting")
                cell.textLabel?.text = "General"
                cell.accessoryType = .disclosureIndicator
        } else if indexPath.section == 1 {
            if #available(iOS 13.0, *) {
                cell.imageView?.image = UIImage(systemName: "bell.fill")
            } else {
                cell.imageView?.image = UIImage(named: "icon_alarm")
            }
            
            cell.textLabel?.text = "Notifications"
            cell.accessoryType = .disclosureIndicator
        } else if indexPath.section == 2 {
            
            if #available(iOS 13.0, *) {
                cell.imageView?.image = UIImage(systemName: "questionmark.circle")
            } else {
                cell.imageView?.image = UIImage(named: "icon_home")
            }
            cell.textLabel?.text = "Help"
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.textLabel?.text = "Sign Out"
            if #available(iOS 13.0, *) {
                cell.imageView?.image = UIImage(systemName: "person.fill")
            }
        }
        
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 3 {
            self.logout()
        }
    }
    
    func logout() {
        MainVC.sharedMainVC?.doLogout()
    }
}

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
    var bHelpCrunchInited: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        let configuration = HCSConfiguration(forOrganization: "leruthstech",
                                                 applicationId: "3",
                                                 applicationSecret: "ARfN5+9unBuWonwaXN9Cg+uLxEAg7BhD1lFYLLTL7yzirgdGIhsioQqgXnTHQGQh65dizk/JdzLozZ5SbxgaGA==")
        
        bHelpCrunchInited = false
        HelpCrunch.initWith(configuration, user: nil) { (error) in
            // Do something on SDK init completion
            if error == nil {
                debugPrint("HelpCruch init success")
                self.bHelpCrunchInited = true
            } else {
                debugPrint("HelpCruch init fail \(error!)")
            }
        }
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
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")

        if indexPath.section == 0 {
            cell.imageView?.image = UIImage(systemName: "gear")
            cell.textLabel?.text = "General"
            cell.accessoryType = .disclosureIndicator
        } else if indexPath.section == 1 {
            cell.imageView?.image = UIImage(systemName: "questionmark.circle")
            cell.textLabel?.text = "Help"
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.textLabel?.text = "Sign Out"
            //cell.imageView?.image = UIImage(systemName: "arrow.uturn.left.square")
            cell.imageView?.image = UIImage(systemName: "arrow.uturn.left")
        }
        
        cell.imageView?.tintColor = .white
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        
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
    }
    
    func logout() {
        MainVC.sharedMainVC?.doLogout()
    }
}

//
//  UserListVC.swift
//  SharePhoto
//
//  Created by Admin on 1/28/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit
import FirebaseFirestore

protocol UserListVCDelegate: AnyObject {
    func didChooseUser(id: String, email: String, name: String)
}

class UserListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var txtUserName: UITextField!
    @IBOutlet weak var tableView: UITableView!

    var listUsers: [QueryDocumentSnapshot]? = nil
    var filteredUsers: [QueryDocumentSnapshot]? = nil
    
    var delegate: UserListVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.navigationController?.title = "Choose User"
        
        self.loadAllUsersList()
    }
    
    func loadAllUsersList() {
        GFSModule.findUsers(name: "") { (success, list) in
            self.listUsers = list

            DispatchQueue.main.async() {
                self.refreshFilteredUsers()
            }
        }
    }
    
    func refreshFilteredUsers() {
        guard let users = self.listUsers else {
            return
        }

        let filter = txtUserName.text
        
        if filter == nil || filter == "" {
            self.filteredUsers = users
        } else {
            self.filteredUsers = []
        
            for user in users {
                let data = user.data()
                let name = data["name"] as! String
                
                if name.lowercased().contains(filter!.lowercased()) {
                    self.filteredUsers! += [user]
                }
            }
        }
        
        self.tableView.reloadData()
    }
    
    @IBAction func onNameFilterChanged(_ sender: Any) {
        self.refreshFilteredUsers()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredUsers?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        
        let user = self.filteredUsers![indexPath.row]
        let data = user.data()
        let name = data["name"] as! String
        let email = data["email"] as! String
        
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = email

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = self.filteredUsers![indexPath.row]
        let data = user.data()
        let userid = user.documentID
        let name = data["name"] as! String
        let email = data["email"] as! String
        
        self.delegate?.didChooseUser(id: userid, email: email, name: name)
        self.navigationController?.popViewController(animated: true)
    }
}

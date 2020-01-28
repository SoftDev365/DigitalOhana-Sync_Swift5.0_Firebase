//
//  UserListVC.swift
//  SharePhoto
//
//  Created by Admin on 1/28/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit

class UserListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var txtUserName: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for:indexPath)
        
        cell.textLabel?.text = "abc"

        return cell
    }
}

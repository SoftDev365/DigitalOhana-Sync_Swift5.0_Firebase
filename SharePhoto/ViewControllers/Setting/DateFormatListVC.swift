//
//  DateFormatListVC.swift
//  SharePhoto
//
//  Created by Admin on 2/5/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit

class DateFormatListVC: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    @IBOutlet weak var tableView: UITableView!
    
    var listFormat: [String] = [ "MM/dd/YYYY", "YYYY-MM-dd", "YYYY/MM/dd", "dd/MM/YYYY" ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.title = "Date Format"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listFormat.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        let format = self.listFormat[indexPath.row]

        cell.textLabel?.text = format.uppercased()
        cell.detailTextLabel?.text = Global.getString(fromDate: Date(), withFormat: format)

        if indexPath.row == 0 {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellSelected = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
        cellSelected?.accessoryType = .none
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        //self.perform(#selector(returnBack), with: nil, afterDelay: 0.25)
    }
    
    @objc func returnBack() {
        self.navigationController?.popViewController(animated: true)
    }
}

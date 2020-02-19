//
//  DateFormatListVC.swift
//  SharePhoto
//
//  Created by Admin on 2/5/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit
import MBProgressHUD

class DateFormatListVC: BaseVC, UITableViewDataSource, UITableViewDelegate  {

    @IBOutlet weak var tableView: UITableView!
    
    enum ViewMode: Int {
       case dateFormat = 0
       case timeFormat = 1
    }
    
    var viewMode: ViewMode = .dateFormat
    var selected: Int = 0
    
    func set(viewMode: ViewMode) {
        self.viewMode = viewMode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        if self.viewMode == .dateFormat {
            self.title = "Date Format"
            self.selected = Global.date_format_index
        } else {
            self.title = "Time Format"
            self.selected = Global.time_format_index
        }

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(onBtnDone))
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.viewMode == .dateFormat {
            return Global.date_format_list.count
        } else {
            return Global.time_format_list.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        let format = self.viewMode == .dateFormat ? Global.date_format_list[indexPath.row] : Global.time_format_list[indexPath.row]

        cell.textLabel?.text = format.uppercased()
        cell.detailTextLabel?.text = Global.getString(fromDate: Date(), withFormat: format)

        if indexPath.row == selected {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellSelected = tableView.cellForRow(at: IndexPath(row: selected, section: 0))
        cellSelected?.accessoryType = .none
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        self.selected = indexPath.row
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        //self.perform(#selector(returnBack), with: nil, afterDelay: 0.25)
    }
    
    @objc func returnBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func alertSaveFailed() {
        let alertController = UIAlertController(title: "Save failed. May be due to Internet Connection!", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel) { (_) in }
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func onBtnDone(sender: UIBarButtonItem) {
        self.showBusyDialog()
        
        if self.viewMode == .dateFormat {
            GFSModule.updateUser(dateFormatIndex: self.selected) { (success) in
                self.hideBusyDialog()
                if success {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.alertSaveFailed()
                }
            }
        } else {
            GFSModule.updateUser(timeFormatIndex: self.selected) { (success) in
                self.hideBusyDialog()
                if success {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.alertSaveFailed()
                }
            }
        }
    }
}

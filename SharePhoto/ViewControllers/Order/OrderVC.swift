//
//  OrderVC.swift
//  SharePhoto
//
//  Created by Arian on 5/22/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit

class OrderVC: UIViewController {
    @IBOutlet weak var orderItemTbl: UITableView!

    var isBilling: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        orderItemTbl.delegate = self
//        self.navigationItem.title = "Order"
//        self.navigationController?.navigationItem.title = "Order"
    }
    
    @IBAction func onConfirmBtn(_ sender: Any) {
        let cell = self.orderItemTbl.cellForRow(at: IndexPath(item: 0, section: 0))
        let screenSize = cell?.detailTextLabel
        print(screenSize?.text)
    }
    
    func getScreenSize() -> String? {
        let cell = orderItemTbl.cellForRow(at: IndexPath(row: 0, section: 0))
        return cell?.detailTextLabel?.text
    }
    
    func setScreenSize( size: String ) {
        let cell = orderItemTbl.cellForRow(at: IndexPath(row: 0, section: 0))
        cell?.detailTextLabel?.text = size
    }

    func getStorageCapacity() -> String? {
        let cell = orderItemTbl.cellForRow(at: IndexPath(row: 1, section: 0))
        return cell?.detailTextLabel?.text
    }
    
    func setStorageCapacity( capacity: String ) {
        let cell = orderItemTbl.cellForRow(at: IndexPath(row: 1, section: 0))
        cell?.detailTextLabel?.text = capacity
    }
}

extension OrderVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else if section == 1 {
            return 6
        } else {
            if isBilling {
                return 6
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as! SwitchCell
        if section == 0 {
            header.lblTitle?.text = "Hardware"
            header.swcOnOff.isHidden = true
        } else if section == 1 {
            header.lblTitle?.text = "Mailing"
            header.swcOnOff.isHidden = true
        } else {
            header.lblTitle?.text = "Billing"
            header.swcOnOff.isHidden = false
            header.swcOnOff.isOn = isBilling
            header.delegate = self
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
            if indexPath.row == 0 {
                cell.textLabel?.text = "Screen Size"
                cell.detailTextLabel?.text = "3.5"
            } else {
                cell.textLabel?.text = "Storage Capacity"
                cell.detailTextLabel?.text = "32GB"
            }
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = .systemGray6
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "InputCell", for: indexPath) as! InputCell
            if indexPath.row == 0 {
//                cell.titleLbl.t0ext = "Full Name"
                cell.inputTF.placeholder = "Full Name"
            } else if indexPath.row == 2 {
//                cell.titleLbl.text = "Street Address"
                cell.inputTF.placeholder = "Street Address"
            } else if indexPath.row == 3 {
//                cell.titleLbl.text = "Town/City"
                cell.inputTF.placeholder = "Town/City"
            } else if indexPath.row == 4 {
//                cell.titleLbl.text = "State"
                cell.inputTF.placeholder = "State"
            } else {
//                cell.titleLbl.text = "Zip Code"
                cell.inputTF.placeholder = "Zip Code"
            }
            cell.backgroundColor = .systemGray6
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section > 0 { return }
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OrderItemListVC") as! OrderItemListVC
        if indexPath.row == 0 {
            vc.item = self.getScreenSize()
            vc.itemList = Global.order_screen_size_list
            vc.listItemCompletionHandler = { (item) in
                self.setScreenSize(size: item)
            }
        } else {
            vc.item = self.getStorageCapacity()
            vc.itemList = Global.order_storage_capacity_list
            vc.listItemCompletionHandler = { (item) in
                self.setStorageCapacity(capacity: item)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
//    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
//        return 0
//    }
}

extension OrderVC: SwitchCellDelegate {
    func switchCell(_ cell: SwitchCell, changedOnOff isOn: Bool) {
        self.isBilling = isOn
        self.orderItemTbl.reloadData()
        let rowCount  = self.orderItemTbl.numberOfRows(inSection: 2)
        
        if rowCount > 0 {
            self.orderItemTbl.scrollToRow(at: IndexPath(row: rowCount-1, section: 2), at: .bottom, animated: true)
        }
    }
}

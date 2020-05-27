//
//  OrderItemListVC.swift
//  SharePhoto
//
//  Created by Arian on 5/23/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit

class OrderItemListVC: UIViewController {
    @IBOutlet weak var listTbl: UITableView!
    
//    var orderVC: OrderVC? = nil
    var itemList: [String]!
    var item: String!
    var listItemCompletionHandler = {( item: String ) in }
    var selectedIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        listTbl.delegate = self
        listTbl.dataSource = self
        selectedIndex = itemList.firstIndex(of: item) ?? 0
    }
}

extension OrderItemListVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        cell.textLabel?.text = itemList[indexPath.row]
        if self.selectedIndex == indexPath.row {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selCell = tableView.cellForRow(at: IndexPath(row: selectedIndex, section: indexPath.section))
        selCell?.accessoryType = .none
        
        let cell = tableView.cellForRow(at: indexPath)
        selectedIndex = indexPath.row
        cell?.accessoryType = .checkmark
        self.listItemCompletionHandler(cell!.textLabel!.text!)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

//
//  NotificationsVC.swift
//  SharePhoto
//
//  Created by Admin on 1/29/20.
//  Copyright © 2020 Admin. All rights reserved.
//

import UIKit

class NotificationsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var notifications: [FSNotificationInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Notifications"
        self.loadNotificationList()
    }
    
    func loadNotificationList() {
        GFSModule.getRecentNotifications { (success, list) in
            self.notifications = list

            DispatchQueue.main.async() {
                self.tableView.reloadData()
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }

    func getDescriptionOfNotification(_ info: FSNotificationInfo) -> String {
        if info.type == NotificationType.upload {
            let description = "\(info.username) uploaded \(info.count) photos"
            return description
        } else {
            let description = "\(info.username) deleted \(info.count) photos"
            return description
        }
    }
       
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let info = self.notifications[indexPath.row]

        cell.textLabel?.text = self.getDescriptionOfNotification(info)
        cell.detailTextLabel?.text = Global.getDateTimeString(interval: info.timestamp)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let info = self.notifications[indexPath.row]
        
        if info.type == NotificationType.upload {
            self.gotoDetailPage(info: info, upload: true)
        } else {
            self.gotoDetailPage(info: info, upload: false)
        }
    }
    
    func gotoDetailPage(info: FSNotificationInfo, upload: Bool) {
        let options = Global.notificationOption
        
        options.bUserName = true
        options.userid = info.userid
        options.userName = info.username
        options.email = info.email
        
        options.bTakenDate = false
        options.bUploadDate = false
        options.bDeletedDate = false
        
        if upload {
            options.bUploadDate = true
            options.uploadDateFrom = info.timestamp - 300
            options.uploadDateTo = info.timestamp + 5
        } else {
            options.bDeletedDate = true
            options.deletedDateFrom = info.timestamp - 30
            options.deletedDateTo = info.timestamp + 5
        }

        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NFDetailPage") as? NFDetailPage {
            vc.notificationInfo = info
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

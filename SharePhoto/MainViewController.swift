//
//  MainViewController.swift
//  SharePhoto
//
//  Created by Admin on 11/7/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit

class MainViewController: UITableViewController {
    
    @IBOutlet var fileListView: UITableView!
    
    let fileArray = ["File1", "File2", "File3"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        
        GDModule.listFiles("root") { (fileList, error) in
            
        }

        /*
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "MainVC")
        self.present(controller, animated: true, completion: nil)
        */
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for:indexPath) as! FileTableViewCell
        
        if indexPath.row%2 == 0 {
            cell.imgThumb.image = UIImage.init(named: "folder_icon")
        } else {
            cell.imgThumb.loadImageUsingCache(withUrl: "https://cdn.arstechnica.net/wp-content/uploads/2018/06/macOS-Mojave-Dynamic-Wallpaper-transition.jpg")
        }
        
        cell.lblTitle.text = fileArray[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            // handle delete (by removing the data from your array and updating the tableview)
        }
    }
}

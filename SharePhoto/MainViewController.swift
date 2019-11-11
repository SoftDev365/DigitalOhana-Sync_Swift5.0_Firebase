//
//  MainViewController.swift
//  SharePhoto
//
//  Created by Admin on 11/7/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import Firebase
import FirebaseStorage

class MainViewController: UITableViewController {

    @IBOutlet var fileListView: UITableView!
    
    var folderID: String?
    var dataContents: [GTLRDrive_File]?
    let activityView = ActivityView()
    
    func setFolderID(_ folderID:String) {
        self.folderID = folderID
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        createNavigationButton()
    }
    
    func createNavigationButton() {
        let buttonSize: CGFloat = 36
        
        let button1 = UIButton(type: .custom)
        button1.setImage(UIImage(named: "newfolder"), for: .normal)
        button1.addTarget(self, action: #selector(onCreateNewFolder), for: .touchUpInside)
        button1.frame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
        button1.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        button1.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
        let barButton1 = UIBarButtonItem(customView: button1)
        
        let button2 = UIButton(type: .custom)
        button2.setImage(UIImage(named: "uploadphoto"), for: .normal)
        button2.addTarget(self, action: #selector(onUploadPhoto), for: .touchUpInside)
        button2.frame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
        button2.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        button2.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
        let barButton2 = UIBarButtonItem(customView: button2)
        
        self.navigationItem.rightBarButtonItems = [barButton2, barButton1]
    }
    
    func createNewFolder(_ name: String?) {
        if name == nil || name == "" {
            return
        }
        
        var folderID = "root"
        if self.folderID != nil {
            folderID = self.folderID!
        }
        
        activityView.showActivityIndicator(self.view, withTitle: "Loading...")
        GDModule.createFolder(name: name!, parentFolderID: folderID) { (folderID) in
            self.activityView.hideActivitiIndicator()
            self.loadFileList()
        }
    }
    
    @objc func onCreateNewFolder() {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "", message: "Input new folder name", preferredStyle: .alert)

        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = ""
        }

        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert!.textFields![0] // Force unwrapping because we know it exists.
            self.createNewFolder(textField.text)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func onUploadPhoto() {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.isMovingFromParent {
            if self.folderID == nil {
                GIDSignIn.sharedInstance()?.signOut()
            }
        }
    }
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadFileList()
    }
    
    func loadCloud() {
        // Get a reference to the storage service using the default Firebase App
        let storage = Storage.storage()

        // Create a storage reference from our storage service
        let storageRef = storage.reference()
        let centralRef = storageRef.child("central")
        
        
        
        centralRef.listAll() { (result, error) in
            if let error = error {
                //...
            }
            
            for prefix in result.prefixes {
                
            }
            
            for item in result.items {
                
            }
        }
    }
    
    func loadFileList() {
        loadCloud()
        
        var folderID = "root"
        if self.folderID != nil {
            folderID = self.folderID!
        }
        
        activityView.showActivityIndicator(self.view, withTitle: "Loading...")
        
        GDModule.listFiles(folderID) { (fileList, error) in
            self.activityView.hideActivitiIndicator()

            if error != nil {
                
            } else {
                self.dataContents = fileList!.files
                self.tableView.reloadData()
            }
        }
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
        if self.dataContents == nil {
            return 0
        }
        
        return self.dataContents!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for:indexPath) as! FileTableViewCell
        
        let file = self.dataContents![indexPath.row]
        
        if file.mimeType! == "application/vnd.google-apps.folder" {
            cell.imgThumb.image = UIImage.init(named: "folder_icon")
        } else {
            
            GDModule.downloadImageFile(file.identifier!) { (image) in
                cell.imgThumb.image = image
            }
            
            //let imageUrl = "https://drive.google.com/uc?export=view&id=\(file.identifier!)"
            //cell.imgThumb.loadImageUsingCache(withUrl: imageUrl)
            //cell.imgThumb.loadImageUsingCache(withUrl: "https://cdn.arstechnica.net/wp-content/uploads/2018/06/macOS-Mojave-Dynamic-Wallpaper-transition.jpg")
        }
        
        cell.lblTitle.text = file.name!
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func deleteRow(_ rowIndex: Int) {
        var actions: [(String, UIAlertAction.Style)] = []
        actions.append(("Delete", UIAlertAction.Style.default))
        actions.append(("Cancel", UIAlertAction.Style.cancel))

        //self = ViewController
        Alerts.showActionsheet(viewController: self, title: "Warning", message: "Are you sure you delete this image?", actions: actions) { (index) in
            print("call action \(index)")
            
            if index == 0 {
                self.dataContents!.remove(at: rowIndex)
                self.tableView.deleteRows(at: [IndexPath.init(row: rowIndex, section: 0)], with: .automatic)
            }
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            self.deleteRow(indexPath.row)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = self.dataContents![indexPath.row]
        
        if file.mimeType! == "application/vnd.google-apps.folder" {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainVC") as? MainViewController
            {
                vc.setFolderID(file.identifier!)
                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
        }
    }
}

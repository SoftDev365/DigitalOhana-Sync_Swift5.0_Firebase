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

class GSExplorerController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet var fileListView: UITableView!
    
    var folderPath: String?
    var fileList: [StorageItem]?
    let activityView = ActivityView()
    
    var imagePicker = UIImagePickerController()

    func setFolderPath(_ folderID:String) {
        self.folderPath = folderID
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = false
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

        activityView.showActivityIndicator(self.view, withTitle: "Loading...")
        GSModule.createFolder(name: name!, parentFolder: self.folderPath!) { (success) in
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
    
    @objc func onUploadPhoto(_ sender: UIButton) {
        chooseImagePickerSource(sender)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.isMovingFromParent {
            if self.folderPath == nil || self.folderPath == "central" {
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
    
    func loadFileList() {
        activityView.showActivityIndicator(self.view, withTitle: "Loading...")
        
        GSModule.getImageFileList(self.folderPath!) { (fileList) in
            self.fileList = fileList
            self.tableView.reloadData()
            
            self.activityView.hideActivitiIndicator()
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
        if self.fileList == nil {
            return 0
        }

        return self.fileList!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for:indexPath) as! FileTableViewCell
        let file = self.fileList![indexPath.row]
        
        if file.isFolder {
            cell.imgThumb.image = UIImage.init(named: "folder_icon")
            cell.lblTitle.text = file.name
        } else {
            GSModule.downloadImageFile(file.file) { (image) in
                cell.imgThumb.image = image
            }
            cell.lblTitle.text = file.name
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let file = self.fileList![indexPath.row]
        
        if file.isFolder {
            return false
        } else {
            return true
        }
    }
    
    func deleteFile(_ rowIndex: Int) {
        let file = self.fileList![rowIndex]
        
        activityView.showActivityIndicator(self.view, withTitle: "Deleting...")
        GSModule.deleteFile(file: file.file) { (result) in
            if result == true {
                self.fileList!.remove(at: rowIndex)
                self.tableView.deleteRows(at: [IndexPath.init(row: rowIndex, section: 0)], with: .automatic)
                
                self.activityView.hideActivitiIndicator()
            }
        }
    }
    
    func deleteRow(_ rowIndex: Int) {
        var actions: [(String, UIAlertAction.Style)] = []
        actions.append(("Delete", UIAlertAction.Style.default))
        actions.append(("Cancel", UIAlertAction.Style.cancel))

        //self = ViewController
        Alerts.showActionsheet(viewController: self, title: "Warning", message: "Are you sure you delete this image?", actions: actions) { (index) in
            print("call action \(index)")

            if index == 0 {
                self.deleteFile(rowIndex)
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
        let file = self.fileList![indexPath.row]
        
        // sub folders
        if file.isFolder {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GSExpVC") as? GSExplorerController
            {
                let folderPath = self.folderPath! + "/" + file.name
                vc.setFolderPath(folderPath)
                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SlideVC") as? ImageSlideViewController
            {
                vc.setFileList(self.fileList!)
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func chooseImagePickerSource(_ sender: UIButton) {
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))

        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallary()
        }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        /*If you want work actionsheet on ipad
        then you have to use popoverPresentationController to present the actionsheet,
        otherwise app will crash on iPad */
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.bounds
            alert.popoverPresentationController?.permittedArrowDirections = .up
        default:
            break
        }

        self.present(alert, animated: true, completion: nil)
    }

    func openCamera() {
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }
        else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    func openGallary() {
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func uploadPhoto(_ imageData: Data, fileName: String?) {
        if fileName == nil || fileName == "" {
            return
        }

        activityView.showActivityIndicator(self.view, withTitle: "Uploading...")
        let imageFileName = fileName! + ".jpg"
        GSModule.uploadFile(name: imageFileName, folderPath: self.folderPath!, data: imageData) { (success) in
            self.activityView.hideActivitiIndicator()
            self.loadFileList()
        }
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let tempImage: UIImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        let imageData = tempImage.jpegData(compressionQuality: 1.0)

        picker.dismiss(animated: true) {
            if( imageData != nil ) {

                let alert = UIAlertController(title: "", message: "Input upload file name", preferredStyle: .alert)
                alert.addTextField { (textField) in
                    textField.text = ""
                }
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                    let textField = alert!.textFields![0]
                    self.uploadPhoto(imageData!, fileName: textField.text)
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true) {
        }
    }
}

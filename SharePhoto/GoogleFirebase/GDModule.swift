//
//  GDModule.swift
//  SharePhoto
//
//  Created by Admin on 11/6/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

class GDModule: NSObject {
    static let driveFolderName = "Ohana Sync"
    static var defaultFolderID: String?
    
    static let service = GTLRDriveService()
    static let imageCache = NSCache<NSString, UIImage>()
    
    static func createFolder( name: String, parentFolderID: String, completion: @escaping (String?) -> Void) {

        let folder = GTLRDrive_File()
        folder.mimeType = "application/vnd.google-apps.folder"
        folder.name = name
        folder.parents = [parentFolderID]
        
        // Google Drive folders are files with a special MIME-type.
        let query = GTLRDriveQuery_FilesCreate.query(withObject: folder, uploadParameters: nil)
        
        self.service.executeQuery(query) { (_, file, error) in
            if error == nil {
                let folder = file as! GTLRDrive_File
                completion(folder.identifier!)
            } else {
                //fatalError(error!.localizedDescription)
                debugPrint(error!)
                completion(nil)
            }
        }
    }
    
    static func getFolderID( name: String, completion: @escaping (String?) -> Void) {
        
        guard let userEmail = Global.email else {
            completion(nil)
            return
        }

        let query = GTLRDriveQuery_FilesList.query()

        // Comma-separated list of areas the search applies to. E.g., appDataFolder, photos, drive.
        query.spaces = "drive"

        // Comma-separated list of access levels to search in. Some possible values are "user,allTeamDrives" or "user"
        query.corpora = "user"
        
        let withName = "name = '\(name)'" // Case insensitive!
        let foldersOnly = "mimeType = 'application/vnd.google-apps.folder'"
        let ownedByUser = "'\(userEmail)' in owners"
        query.q = "\(withName) and \(foldersOnly) and \(ownedByUser)"

        service.executeQuery(query) { (_, result, error) in
            if( error != nil ) {
                debugPrint(error!)
                completion(nil)
                return
            }
      
            let folderList = result as! GTLRDrive_FileList

            // For brevity, assumes only one folder is returned.
            completion(folderList.files?.first?.identifier)
        }
    }
    
    static func getDefaultFolderID( completion: @escaping (String?) -> Void) {
        
        if self.defaultFolderID != nil {
            completion(self.defaultFolderID)
            return
        }
        
        getFolderID( name: self.driveFolderName) { folderID in
            if folderID == nil {
                self.createFolder(name: self.driveFolderName, parentFolderID: "root") { (createdFolderID) in
                    self.defaultFolderID = folderID
                    completion(folderID)
                }
            } else {
                // Folder already exists
                self.defaultFolderID = folderID
                completion(folderID)
            }
        }
    }
    
    // search file or folder
    static func search(_ fileName: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1
        query.q = "name contains '\(fileName)'"
            
        service.executeQuery(query) { (ticket, results, error) in
            onCompleted((results as? GTLRDrive_FileList)?.files?.first?.identifier, error)
        }
    }

    // search file or folder
    static func checkExists(fileTitle: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1
        query.q = "name = '\(fileTitle)+.jpg'"
            
        service.executeQuery(query) { (ticket, results, error) in
            onCompleted((results as? GTLRDrive_FileList)?.files?.first?.identifier, error)
        }
    }
    
    static func listFiles(folderID: String, onCompleted: @escaping (GTLRDrive_FileList?) -> ()) {
        
        let query = GTLRDriveQuery_FilesList.query()
        
        //query.pageSize = 100

        // Comma-separated list of areas the search applies to. E.g., appDataFolder, photos, drive.
        query.spaces = "drive"
        
        // Comma-separated list of access levels to search in. Some possible values are "user,allTeamDrives" or "user"
        query.corpora = "user"

        let fileFilter = "(mimeType = 'application/vnd.google-apps.folder' or mimeType = 'image/jpeg' or mimeType = 'image/png') and trashed=false"

        //let ownedByUser = "'\(user!.profile!.email!)' in owners"
        
        //query.q = "'root' in parents"
        //query.q = "'\(folderID)' in parents"
        //query.q = "\(foldersOnly) and \(ownedByUser)"
        query.q = "\(fileFilter) and '\(folderID)' in parents"
        query.fields = "files(id, name, thumbnailLink)"
            
        service.executeQuery(query) { (ticket, result, error) in
            if let error = error {
                debugPrint(error)
                onCompleted(nil)
            } else {                
                onCompleted(result as? GTLRDrive_FileList)
            }
            
        }
    }
    
    static func listFiles(folderName: String, onCompleted: @escaping (GTLRDrive_FileList?) -> ()) {
        search(folderName) { (folderID, error) in
            guard let folderID = folderID else {
                onCompleted(nil)
                return
            }

            self.listFiles(folderID: folderID, onCompleted: onCompleted)
        }
    }
    
    static func listFiles(onCompleted: @escaping (GTLRDrive_FileList?) -> ()) {
        if self.defaultFolderID == nil {
            self.getDefaultFolderID { (folderID) in
                if folderID == nil {
                    onCompleted(nil)
                } else {
                    self.listFiles(folderID: folderID!, onCompleted: onCompleted)
                }
            }
        } else {
            self.listFiles(folderID: self.defaultFolderID!, onCompleted: onCompleted)
        }
    }
    
    static func downloadImage(fileID: String, onCompleted: @escaping (String?, UIImage?) -> ()) {
        // check cached image
        if let cachedImage = self.imageCache.object(forKey: fileID as NSString)  {
            onCompleted(fileID, cachedImage)
        }

        let imageUrl = "https://www.googleapis.com/drive/v3/files/\(fileID)?alt=media"
        //let imageUrl = "https://drive.google.com/uc?export=view&id=\(fileID)"
        let fetcher = service.fetcherService.fetcher(withURLString: imageUrl)
        fetcher.beginFetch { (data, error) in
            if error != nil {
                onCompleted(fileID, nil)
            } else {
                let image = UIImage.init(data: data!)
                if image != nil {
                    self.imageCache.setObject(image!, forKey: fileID as NSString)
                }
                onCompleted(fileID, image)
            }
        }
    }
    
    static func uploadImage(_ image: UIImage, fileTitle: String, folderID: String, onCompleted: @escaping (Bool) -> ()) {

        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            onCompleted(false)
            return
        }

        let mimeType = "image/jpeg"
        let file = GTLRDrive_File()
        file.name = fileTitle + ".jpg"
        file.parents = [folderID]
        
        // Optionally, GTLRUploadParameters can also be created with a Data object.
        let uploadParameters = GTLRUploadParameters(data: imageData, mimeType: mimeType)
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
        
        service.uploadProgressBlock = { _, totalBytesUploaded, totalBytesExpectedToUpload in
            // This block is called multiple times during upload and can
            // be used to update a progress indicator visible to the user.
        }
        
        service.executeQuery(query) { (_, result, error) in
            if error != nil {
                debugPrint(error!)
                onCompleted(false)
            } else {
                // Successful upload if no error is returned.
                onCompleted(true)
            }
        }
    }
    
    static func uploadFile( name: String,
                            folderID: String,
                            fileURL: URL,
                            mimeType: String ) {
        
        let file = GTLRDrive_File()
        file.name = name
        file.parents = [folderID]
        
        // Optionally, GTLRUploadParameters can also be created with a Data object.
        let uploadParameters = GTLRUploadParameters(fileURL: fileURL, mimeType: mimeType)
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
        
        service.uploadProgressBlock = { _, totalBytesUploaded, totalBytesExpectedToUpload in
            // This block is called multiple times during upload and can
            // be used to update a progress indicator visible to the user.
        }
        
        service.executeQuery(query) { (_, result, error) in
            if error != nil {
                debugPrint(error!)
            }
            // Successful upload if no error is returned.
        }
    }
    
    static func uploadMyFile() {
        let fileURL = Bundle.main.url(
            forResource: "my-image", withExtension: ".png")
        uploadFile(
            name: "my-image.png",
            folderID: defaultFolderID!,
            fileURL: fileURL!,
            mimeType: "image/png")
    }
}

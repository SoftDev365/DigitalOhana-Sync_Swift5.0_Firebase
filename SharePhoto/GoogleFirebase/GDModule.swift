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
    static let service = GTLRDriveService()
    static var user: GIDGoogleUser?
    static var uploadFolderID: String?
    
    static let imageCache = NSCache<NSString, UIImage>()
    
    // listing files
    static func search(_ fileName: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1
        query.q = "name contains '\(fileName)'"
            
        service.executeQuery(query) { (ticket, results, error) in
            onCompleted((results as? GTLRDrive_FileList)?.files?.first?.identifier, error)
        }
    }
    
    static func listFiles(_ folderID: String, onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> ()) {
        
        let query = GTLRDriveQuery_FilesList.query()
        
        if self.user == nil {
            return
        }
        
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
            
        service.executeQuery(query) { (ticket, result, error) in
            onCompleted(result as? GTLRDrive_FileList, error)
        }
    }
    
    static func listFilesInFolder(_ folder: String, onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> ()) {
        search(folder) { (folderID, error) in
            guard let ID = folderID else {
                onCompleted(nil, error)
                return
            }
            self.listFiles(ID, onCompleted: onCompleted)
        }
    }
    
    static func downloadImageFile(_ fileID: String, onCompleted: @escaping (UIImage?) -> ()) {
        // check cached image
        if let cachedImage = self.imageCache.object(forKey: fileID as NSString)  {
            onCompleted(cachedImage)
        }

        let imageUrl = "https://www.googleapis.com/drive/v3/files/\(fileID)?alt=media"
        //let imageUrl = "https://drive.google.com/uc?export=view&id=\(fileID)"
        let fetcher = service.fetcherService.fetcher(withURLString: imageUrl)
        fetcher.beginFetch { (data, error) in
            if error != nil {
                onCompleted(nil)
            } else {
                let image = UIImage.init(data: data!)
                if image != nil {
                    self.imageCache.setObject(image!, forKey: fileID as NSString)
                }
                onCompleted(image)
            }
        }
    }

    static func populateFolderID() {
        let myFolderName = "SharedPhoto"
        getFolderID(
            name: myFolderName,
            service: service,
            user: user!) { folderID in
            if folderID == nil {
                self.createFolder(name: myFolderName, parentFolderID: "root") {
                    self.uploadFolderID = $0
                }
            } else {
                // Folder already exists
                self.uploadFolderID = folderID
            }
        }
    }
    
    static func getFolderID(
        name: String,
        service: GTLRDriveService,
        user: GIDGoogleUser,
        completion: @escaping (String?) -> Void) {
        
        let query = GTLRDriveQuery_FilesList.query()

        // Comma-separated list of areas the search applies to. E.g., appDataFolder, photos, drive.
        query.spaces = "drive"
        
        // Comma-separated list of access levels to search in. Some possible values are "user,allTeamDrives" or "user"
        query.corpora = "user"
            
        let withName = "name = '\(name)'" // Case insensitive!
        let foldersOnly = "mimeType = 'application/vnd.google-apps.folder'"
        let ownedByUser = "'\(user.profile!.email!)' in owners"
        query.q = "\(withName) and \(foldersOnly) and \(ownedByUser)"
        
        service.executeQuery(query) { (_, result, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
                                     
            let folderList = result as! GTLRDrive_FileList

            // For brevity, assumes only one folder is returned.
            completion(folderList.files?.first?.identifier)
        }
    }
    
    static func createFolder(
        name: String,
        parentFolderID: String,
        completion: @escaping (String) -> Void) {
        
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
                fatalError(error!.localizedDescription)
                completion("")
            }
        }
    }
    
    static func uploadFile(
        name: String,
        folderID: String,
        fileURL: URL,
        mimeType: String,
        service: GTLRDriveService) {
        
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
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
            // Successful upload if no error is returned.
        }
    }
    
    static func uploadMyFile() {
        let fileURL = Bundle.main.url(
            forResource: "my-image", withExtension: ".png")
        uploadFile(
            name: "my-image.png",
            folderID: uploadFolderID!,
            fileURL: fileURL!,
            mimeType: "image/png",
            service: service)
    }
}

// Google Firestore module

import UIKit
import Firebase
import FirebaseStorage
import FirebaseDatabase
import FirebaseFirestore
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

class GFSModuleSync: NSObject {
    
    static func getAllPhotos(withDeleted: Bool) -> [FSPhotoInfo] {
        var photos: [FSPhotoInfo] = []
        var bProcessing = true
        
        GFSModule.getAllPhotos(withDeleted: withDeleted, onCompleted: { (success, result) in
            photos = result
            bProcessing = false
        })

        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.005)
        }

        return photos
    }
    
    static func searchPhoto(cloudDocumentID: String) -> Bool {
        var bResult: Bool = false
        var bProcessing = true
        
        GFSModule.searchPhoto(cloudDocumentID: cloudDocumentID) { (success, _) in
            bResult = success
            bProcessing = false
        }

        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.005)
        }

        return bResult
    }
    
    static func searchPhoto(driveFileID: String) -> Bool {
        var bResult: Bool = false
        var bProcessing = true
        
        GFSModule.searchPhoto(driveFileID: driveFileID) { (success, _) in
            bResult = success
            bProcessing = false
        }
        
        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.005)
        }

        return bResult
    }
    
    static func registerPhoto(info: FSPhotoInfo) -> String? {
        var result: String? = nil
        var bProcessing = true
        
        GFSModule.registerPhoto(info: info) { (success, documentID) in
            result = documentID
            bProcessing = false
        }
        
        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.005)
        }

        return result
    }
    
    static func updatePhotoToValid(photoID: String) -> Bool {
        var bResult: Bool = false
        var bProcessing = true
        
        GFSModule.updatePhotoToValid(photoID: photoID) { (success) in
            bResult = success
            bProcessing = false
        }
        
        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.005)
        }

        return bResult
    }
    
    static func deletePhoto(photoID: String) -> Bool {
        var bResult: Bool = false
        var bProcessing = true
        
        GFSModule.deletePhoto(photoID: photoID) { (success) in
            bResult = success
            bProcessing = false
        }

        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.005)
        }

        return bResult
    }
    
    static func registerNotification(info: FSNotificationInfo) -> Bool {
        var bResult: Bool = false
        var bProcessing = true
        
        GFSModule.registerNotification(info: info) { (success, _) in
            bResult = success
            bProcessing = false
        }

        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.005)
        }

        return bResult
    }
}

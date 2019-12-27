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
    
    static func registerUser() -> Bool {
        
        guard let user = Global.user else { return false }
        
        var bResult = false
        var bProcessing = true

        let db = Firestore.firestore()

        db.collection("users").document(user.userID).setData([
            "email": user.profile.email!,
            "name": user.profile.name!,
        ]) { err in
            if let err = err {
                debugPrint(err)
                bResult = false
            } else {
                //self.userID = ref!.documentID
                bResult = true
            }
            bProcessing = false
        }

        // block while processing
        while bProcessing {
            Thread.sleep(forTimeInterval: 0.005)
        }
        
        return bResult
    }
    
    static func getAllPhotos() -> [[String:Any]] {
        var photos: [[String:Any]] = []
        var bProcessing = true
        
        GFSModule.getAllPhotos { (success, result) in
            photos = result
            bProcessing = false
        }
    
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
            Thread.sleep(forTimeInterval: 0.001)
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
            Thread.sleep(forTimeInterval: 0.001)
        }

        return bResult
    }
    
    static func registerPhoto(info: [String: Any]) -> String? {
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
}

// Google Firestore module

import UIKit
import Firebase
import FirebaseStorage
import FirebaseDatabase
import FirebaseFirestore
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

class GFSModule: NSObject {
    static var userID: String?
    
    static func fetchUsers() {
        let db = Firestore.firestore()
        let refUsers = db.collection("users")
        
        refUsers.getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting docuemts:\(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
    }
    
    static func registerUser() {
        //fetchUsers()
        
        guard let user = GUser.user else { return }

        let db = Firestore.firestore()
        //var ref: DocumentReference? = nil

        db.collection("users").document(user.userID).setData([
        /*ref = db.collection("users").addDocument(data: [*/
            "email": user.profile.email!,
            "name": user.profile.name!,
        ]) { err in
            if let err = err {
                debugPrint(err)
            } else {
                //self.userID = ref!.documentID
            }
        }
    }
    
    static func registerPhoto(createDate: String, onCompleted: @escaping (Bool, String?) -> ()) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let dateNow = df.string(from: Date())
        
        let userID = GUser.user!.userID!
        let email = GUser.email!
        let username = GUser.user!.profile.name!
        
        let db = Firestore.firestore()
        var ref: DocumentReference? = nil

        ref = db.collection("photos").addDocument(data: [
            "create": createDate,
            "upload": dateNow,
            "userid": userID,
            "email": email,
            "name": username,
            "valid": false
        ]) { err in
            if let err = err {
                debugPrint(err)
                onCompleted(false, nil)
            } else {
                debugPrint("---------register photo document id:\(ref!.documentID)----------")
                onCompleted(true, ref!.documentID)
            }
        }
    }
    
    static func updatePhotoToValid(photoID: String, onCompleted: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()

        db.collection("photos").document(photoID).updateData([
            "valid": true
        ]) { err in
            if let err = err {
                debugPrint(err)
                onCompleted(false)
            } else {
                onCompleted(true)
            }
        }
    }
    
    static func uploadPhoto() {
        
    }
}

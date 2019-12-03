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
                print("Error getting users docuemts:\(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
    }
    
    static func registerUser() {
        //fetchUsers()
        
        guard let user = Global.user else { return }

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
    
    static func getAllPhotos(onCompleted: @escaping (Bool, [[String:Any]]) -> ()) {
        let db = Firestore.firestore()
        let refPhotos = db.collection("photos")
        
        refPhotos.getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting photos docuemts:\(err)")
                onCompleted(false, [])
            } else {
                var result = [[String:Any]]()
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    
                    // check validation
                    let data = document.data()
                    let valid = data["valid"] as! Bool
                    
                    if valid == true {
                        let item = ["id": document.documentID, "data": data] as [String:Any]
                        result += [item]
                    }
                }
                onCompleted(true, result)
            }
        }
    }
    
    static func registerPhoto(createDate: String, onCompleted: @escaping (Bool, String?) -> ()) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let dateNow = df.string(from: Date())
        
        let userID = Global.user!.userID!
        let email = Global.email!
        let username = Global.user!.profile.name!
        
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
}

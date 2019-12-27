// Google Firestore module

import UIKit
import Firebase
import FirebaseStorage
import FirebaseDatabase
import FirebaseFirestore
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

enum PhotoField: String {
    case taken = "taken"
    case uploaded = "uploaded"
    case location = "location"
    case userid = "userid"
    case email = "eamil"
    case username = "username"
    case size = "size"
    case tag = "tag"
    case sourceType = "sourceType"
    case sourceID = "sourceID"
    case valid = "valid"
}

enum SourceType: Int {
    case asset = 0
    case drive = 1
}

class GFSModule: NSObject {

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
                    //print("\(document.documentID) => \(document.data())")

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
    
    static func searchPhoto(cloudDocumentID: String, onCompleted: @escaping (Bool, String?) -> ()) {
        let email = Global.email!
        let db = Firestore.firestore()

        db.collection("photos").document(cloudDocumentID).getDocument() { (document, error) in
            if let error = error {
                print("Error getting photos docuemts:\(error)")
                onCompleted(false, nil)
            } else {
                if let document = document {
                    if document.exists {
                        onCompleted(true, snapshot.documentID)
                    } else {
                        onCompleted(false, nil)
                    }
                } else {
                    onCompleted(false, nil)
                }
            }
        }
    }
    
    static func searchPhoto(driveFileID: String, onCompleted: @escaping (Bool, String?) -> ()) {
        let email = Global.email!
        let db = Firestore.firestore()
        var ref: DocumentReference? = nil

        db.collection("photos")
            .whereField(PhotoField.email, isEqualTo: email)
            .whereField(PhotoField.sourceType, isEqualTo: "drive")
            .whereField(PhotoField.sourceID, isEqualTo: driveFileID)
            .getDocuments() { (querySnapshot, error) in
                if let error = error {
                    print("Error getting photos docuemts:\(error)")
                    onCompleted(false, nil)
                } else {
                    for document in querySnapshot!.documents {
                        onCompleted(true, document.documentID)
                        return
                    }
                }
        }
    }
    
    static func registerPhoto(info: [PhotoField: Any], onCompleted: @escaping (Bool, String?) -> ()) {
        
        let uploaded = Date().timeIntervalSince1970
        let userID = Global.user!.userID!
        let email = Global.email!
        let username = Global.user!.profile.name!
        
        let data = info + [PhotoField.uploaded: uploaded,
                           PhotoField.userid: userID,
                           PhotoField.email: email,
                           PhotoField.username: username,
                           PhotoField.valid: false]

        let db = Firestore.firestore()
        var ref: DocumentReference? = nil
        
        ref = db.collection("photos").addDocument(data: data) { err in
            if let err = err {
                debugPrint(err)
                onCompleted(false, nil)
            } else {
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
    
    static func deletePhoto(photoID: String, onCompleted: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()

        db.collection("photos").document(photoID).delete { (err) in
            if let err = err {
                debugPrint(err)
                onCompleted(false)
            } else {
                onCompleted(true)
            }
        }
    }
}

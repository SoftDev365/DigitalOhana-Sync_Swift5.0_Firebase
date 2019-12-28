// Google Firestore module

import UIKit
import Firebase
import FirebaseStorage
import FirebaseDatabase
import FirebaseFirestore
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

class PhotoField {
    static let taken: String = "taken"
    static let uploaded: String = "uploaded"
    static let location: String = "location"
    static let userid: String = "userid"
    static let email: String = "email"
    static let username: String = "username"
    static let size: String = "size"
    static let tag: String = "tag"
    static let sourceType: String = "sourceType"
    static let sourceID: String = "sourceID"
    static let valid: String = "valid"
}

class SourceType {
    static let asset: Int = 0
    static let drive: Int = 1
}

extension Dictionary {
    mutating func merge(dict: [Key: Value]){
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
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
        let db = Firestore.firestore()

        db.collection("photos").document(cloudDocumentID).getDocument() { (document, error) in
            if let error = error {
                print("Error getting photos docuemts:\(error)")
                onCompleted(false, nil)
            } else {
                if let document = document {
                    if document.exists {
                        onCompleted(true, document.documentID)
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
                    
                    onCompleted(false, nil)
                }
        }
    }
    
    static func registerPhoto(info: [String: Any], onCompleted: @escaping (Bool, String?) -> ()) {
        
        let uploaded = Date().timeIntervalSince1970
        let userID = Global.user!.userID!
        let email = Global.email!
        let username = Global.user!.profile.name!
        
        var  data = [PhotoField.uploaded: uploaded,
                    PhotoField.userid: userID,
                    PhotoField.email: email,
                    PhotoField.username: username,
                    PhotoField.valid: false] as [String : Any]
        
        data.merge(dict: info)

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

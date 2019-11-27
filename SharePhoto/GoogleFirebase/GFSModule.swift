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
        
        fetchUsers()
        
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
}

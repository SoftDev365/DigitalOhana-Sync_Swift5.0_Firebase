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
    
    static func registerUser() {
        guard let user = GUser.user else { return }

        let db = Firestore.firestore()
        var ref: DocumentReference? = nil

        ref = db.collection("users").addDocument(data: [
            "email": user.profile.email!,
            "name": user.profile.name!,
        ]) { err in
            if let err = err {
                debugPrint(err)
            } else {
                self.userID = ref!.documentID
            }
        }
    }
}

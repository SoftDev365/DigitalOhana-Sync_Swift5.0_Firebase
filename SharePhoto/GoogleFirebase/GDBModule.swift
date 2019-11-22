
// Google Realtime Database Module

import UIKit
import Firebase
import FirebaseStorage
import FirebaseDatabase
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

class GDBModule: NSObject {
    static func registerUser() {
        guard let user = GUser.user else { return }

        let dbRef = Database.database().reference()
        let keyPath = "users/\(user.userID!)"
        var userInfo = [String:String]()
        
        userInfo["email"] = user.profile.email
        userInfo["name"] = user.profile.name

        dbRef.child(keyPath).setValue(userInfo)
    }
}

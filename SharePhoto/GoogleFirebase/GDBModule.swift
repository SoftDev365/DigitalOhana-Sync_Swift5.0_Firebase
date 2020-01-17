
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
        guard let userid = Global.userid else { return }
        guard let email = Global.email else { return }

        let dbRef = Database.database().reference()
        let keyPath = "users/\(userid)"
        var userInfo = [String:String]()
        
        userInfo["email"] = userid
        userInfo["name"] = email

        dbRef.child(keyPath).setValue(userInfo)
    }
}

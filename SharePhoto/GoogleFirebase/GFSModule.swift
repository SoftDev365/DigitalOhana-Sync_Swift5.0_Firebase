// Google Firestore module

import UIKit
import Firebase
import FirebaseStorage
import FirebaseDatabase
import FirebaseFirestore
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

class UserField {
    static let userid: String = "userid"
    static let email: String = "email"
    static let displayname: String = "name"
    static let originname: String = "origin_name"
    static let allow: String = "allow"
    static let dateFormatIndex: String = "dateFormatIndex"
    static let timeFormatIndex: String = "timeFormatIndex"
    static let auto_upload: String = "AutoUpload"
}

class PhotoField {
    static let taken: String = "taken"
    static let uploaded: String = "uploaded"
    static let location: String = "location"
    static let userid: String = "userid"
    static let email: String = "email"
    static let username: String = "username"
    static let sizeWidth: String = "sizeWidth"
    static let sizeHeight: String = "sizeHeight"
    static let tag: String = "tag"
    static let sourceType: String = "sourceType"
    static let sourceID: String = "sourceID"
    static let valid: String = "valid"
    static let deleted: String = "delete"
    static let deletedTime: String = "deletedTime"
}

class NotificationField {
    static let timestamp: String = "timestamp"
    static let userid: String = "userid"
    static let email: String = "email"
    static let username: String = "username"
    static let type: String = "type"
    static let count: String = "count"
}

class FrameField {
    static let frameid: String = "ID"
    static let title: String = "title"
}

class FramePhotoField {
    static let regtime: String = "regtime"
    static let userid: String = "userid"
}

enum SourceType : Int {
    case asset = 0
    case drive = 1
}

class FSPhotoInfo {
    var valid: Bool = false             // validation (false, true)
    
    var id: String
    
    var userid: String                  // owner id, users collection on firestore db
    var email: String                   // owner email address
    var username: String                // owner name

    var sourceType: SourceType = .asset // from asset (0) or drive (1)
    var sourceID: String                // asset id or drive file id

    var taken: TimeInterval = 0         // photo taken time
    var uploaded: TimeInterval = 0      // photo uploaded time
    var location: String                // photo taken location
    
    var size: CGSize = CGSize(width: 0, height: 0) // photo dimensions
    var tag: String                     // tag

    var deleted: Bool = false           // deleted flag
    var deletedTime: TimeInterval = 0   // time interval
    
    init() {
        self.id = ""
        self.userid = Global.userid!
        self.email = Global.email!
        self.username = Global.username!

        self.sourceID = ""
        self.sourceType = .asset
        
        self.size = CGSize(width: 0, height: 0)
        self.location = ""
        self.tag = ""
        
        self.uploaded = Date().timeIntervalSince1970
        self.valid = false
        
        self.deleted = false
    }
}

class NotificationType {
    static let upload = 0
    static let delete =  1
}

class FSNotificationInfo {
    var id: String
    
    var userid: String                  // owner id, users collection on firestore db
    var email: String                   // owner email address
    var username: String                // owner name

    var timestamp: TimeInterval = 0     // event timestamp
    
    var type: Int = 0                   // 0: Upload, 1: Delete
    var count: Int = 0                  // photo count
    
    init() {
        self.id = ""
        self.userid = Global.userid!
        self.email = Global.email!
        self.username = Global.username!
        self.timestamp = Date().timeIntervalSince1970
    }
}

class FSFrameInfo {
    var frameid: String    // frameid, same as RPI device unique serial number
    var title: String      // frame name

    var reg_time: TimeInterval = 0     // register timestamp

    init() {
        self.frameid = ""
        self.title = ""
        self.reg_time = Date().timeIntervalSince1970
    }
}

class FSFramePhotoInfo {
    var id: String
    
    var userid: String                  // owner id, users collection on firestore db
    var regtime: TimeInterval = 0       // photo registered time
    
    init() {
        self.id = ""
        self.userid = Global.userid!
    }
}

extension Dictionary {
    mutating func merge(dict: [Key: Value]){
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}

class GFSModule: NSObject {
    
    static func getCollectionNameOfFrame(ID: String) -> String {
        return "frame_" + ID;
    }

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

    static func findUsers(name: String, onCompleted: @escaping (Bool, [QueryDocumentSnapshot]?) -> ()) {
        let db = Firestore.firestore()
        let refUsers = db.collection("users")

        if name == "" {
            refUsers.getDocuments() { (querySnapshot, error) in
                if let error = error {
                    print("Error getting photos docuemts:\(error)")
                    onCompleted(false, nil)
                } else {
                    onCompleted(true, querySnapshot!.documents)
                }
            }
        } else {
            refUsers.whereField("name", arrayContains: name)
                .getDocuments() { (querySnapshot, error) in
                if let error = error {
                    print("Error getting photos docuemts:\(error)")
                    onCompleted(false, nil)
                } else {
                    onCompleted(true, querySnapshot!.documents)
                }
            }
        }
    }
    
    static func registerUser() {
        //fetchUsers()
        
        guard let userid = Global.userid else { return }
        guard let username = Global.username else { return }
        guard let email = Global.email else { return }

        let db = Firestore.firestore()
        
        // db.collection("users").document(userid).updateData([
        // register new user (or overwrite newly, so must check first if exists)
        db.collection("users").document(userid).setData([
            UserField.email: email,
            UserField.displayname: username,
            UserField.originname: username,
            UserField.dateFormatIndex: 0,
            UserField.auto_upload: true,
            UserField.allow: true
        ]) { err in
            if let err = err {
                debugPrint(err)

                /*
                db.collection("users").document(userid).setData([
                    "email": email,
                    "name": username,
                    "allow": false
                ]) { err in
                    if let err = err {
                        debugPrint(err)
                    } else {
                        //self.userID = ref!.documentID
                    }
                }*/
            } else {
                
            }
        }
    }
    
    // update user display name
    static func updateUser(displayName: String, onCompleted: @escaping (Bool) -> ()) {
        guard let userid = Global.userid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userid).updateData([
            UserField.displayname: displayName
        ]) { err in
            if let err = err {
                debugPrint(err)
                onCompleted(false)
            } else {
                Global.username = displayName
                onCompleted(true)
            }
        }
    }
    
    // update user prefered date format
    static func updateUser(dateFormatIndex: Int, onCompleted: @escaping (Bool) -> ()) {
        guard let userid = Global.userid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userid).updateData([
            UserField.dateFormatIndex: dateFormatIndex
        ]) { err in
            if let err = err {
                debugPrint(err)
                onCompleted(false)
            } else {
                Global.date_format_index = dateFormatIndex
                Global.date_format = Global.date_format_list[dateFormatIndex]
                onCompleted(true)
            }
        }
    }
    
    // update user prefered time format
    static func updateUser(timeFormatIndex: Int, onCompleted: @escaping (Bool) -> ()) {
        guard let userid = Global.userid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userid).updateData([
            UserField.timeFormatIndex: timeFormatIndex
        ]) { err in
            if let err = err {
                debugPrint(err)
                onCompleted(false)
            } else {
                Global.time_format_index = timeFormatIndex
                Global.time_format = Global.time_format_list[timeFormatIndex]
                onCompleted(true)
            }
        }
    }
    
    // update user AutoUpload setting (true or false)
    static func updateUser(autoUpload: Bool, onCompleted: @escaping (Bool) -> ()) {
        guard let userid = Global.userid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userid).updateData([
            UserField.auto_upload: autoUpload
        ]) { err in
            if let err = err {
                debugPrint(err)
                onCompleted(false)
            } else {
                Global.bAutoUpload = autoUpload
                onCompleted(true)
            }
        }
    }
    
    static func getUserInfo(ID: String, onCompleted: @escaping (DocumentSnapshot?) -> ()) {
        let db = Firestore.firestore()

        db.collection("users").document(ID).getDocument { (snapshot, error) in
            if let err = error {
                debugPrint(err)
                onCompleted(nil)
            } else {
                onCompleted(snapshot)
            }
        }
    }
    
    static func checkAllowOfUser(ID: String, onCompleted: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()

        db.collection("users").document(ID).getDocument { (snapshot, error) in
            if let err = error {
                debugPrint(err)
            } else {
                let data = snapshot?.data()
                if data == nil {
                    onCompleted(false)
                } else {
                    let allow = data!["allow"] as? Bool
                    if allow == true {
                        onCompleted(true)
                    } else {
                        onCompleted(false)
                    }
                }
            }
        }
    }
    
    static func convertToPhotoInfo(document: QueryDocumentSnapshot) -> FSPhotoInfo {
        let photoInfo = FSPhotoInfo()
        
        let data = document.data()
        
        photoInfo.id = document.documentID
        
        photoInfo.userid = (data[PhotoField.userid] as! String)
        photoInfo.email = (data[PhotoField.email] as! String)
        photoInfo.username = (data[PhotoField.username] as! String)
        
        //let srcType = (data[PhotoField.sourceType] as! Int)
        //if srcType == 0 {
        //    photoInfo.sourceType = .asset
        //} else if srcType == 1 {
        //    photoInfo.sourceType = .drive
        //}

        let sourceType = data[PhotoField.sourceType]
        if sourceType == nil {
            photoInfo.sourceType = .asset
        } else if sourceType is SourceType {
            photoInfo.sourceType = (sourceType as! SourceType)
        } else if sourceType is Int {
            photoInfo.sourceType = SourceType(rawValue: sourceType as! Int) ?? .asset
        }
        
        photoInfo.sourceID = (data[PhotoField.sourceID] as! String)
        photoInfo.valid = (data[PhotoField.valid] as! Bool)
        
        let taken = data[PhotoField.taken]
        if taken is TimeInterval {
            photoInfo.taken = taken as! TimeInterval
        } else {
            photoInfo.taken = Date().timeIntervalSince1970
        }

        let uploaded = data[PhotoField.uploaded]
        if uploaded is TimeInterval {
            photoInfo.uploaded = uploaded as! TimeInterval
        } else {
            photoInfo.uploaded = Date().timeIntervalSince1970
        }
        
        let location = data[PhotoField.location]
        if location == nil {
            photoInfo.location = ""
        } else if location is String {
            photoInfo.location = (location as! String)
        } else {
            photoInfo.location = ""
        }

        let sizeWidth = data[PhotoField.sizeWidth]
        let sizeHeight = data[PhotoField.sizeHeight]
        if sizeWidth is CGFloat && sizeHeight is CGFloat  {
            photoInfo.size = CGSize(width: sizeWidth as! CGFloat, height: sizeHeight as! CGFloat)
        } else {
            photoInfo.size = CGSize(width: 0, height: 0)
        }
        
        let deletedFlag = data[PhotoField.deleted]
        if deletedFlag is Bool {
            photoInfo.deleted = (data[PhotoField.deleted] as! Bool)
        } else {
            photoInfo.deleted = false
        }
        
        let deletedTime = data[PhotoField.deletedTime]
        if deletedTime is TimeInterval {
            photoInfo.deletedTime = deletedTime as! TimeInterval
        } else {
            photoInfo.deletedTime = 0
        }
        
        return photoInfo
    }
    
    /*
    static func searchPhotosByOptions(onCompleted: @escaping (Bool, [FSPhotoInfo]) -> ()) {
        let options = Global.searchOption
        let db = Firestore.firestore()
        let refPhotos = db.collection("photos")
        var query = refPhotos.whereField(PhotoField.valid, isEqualTo: true)
        
        if options.bUserName == true && options.userid != nil {
            query = query.whereField(PhotoField.userid, isEqualTo: options.userid!)
        }
        
        if options.bUploadDate == true && options.uploadDateFrom != nil && options.uploadDateTo != nil {
            query = query.whereField(PhotoField.uploaded, isGreaterThanOrEqualTo: options.uploadDateFrom!)
            query = query.whereField(PhotoField.uploaded, isLessThanOrEqualTo: options.uploadDateTo!)
        }
        
        query = query.order(by: PhotoField.uploaded, descending: true)
        
        query.getDocuments() { (querySnapshot, error) in
            if let error = error {
                print("Error getting photos documents:\(error)")
                onCompleted(false, [])
            } else {
                var result = [FSPhotoInfo]()

                for document in querySnapshot!.documents {
                    let info = self.convertToPhotoInfo(document: document)
                    
                    if options.bTakenDate == true && options.takenDateFrom != nil && options.takenDateTo != nil {
                        if info.taken < options.takenDateFrom! || info.taken > options.takenDateTo! {
                            continue
                        }
                    }
                    
                    result += [info]
                }
                
                Global.sharedCloudPhotos = result
                onCompleted(true, result)
            }
        }
    }*/
    
    static func searchPhotosBy(withDeleted: Bool, options: SearchOption, onCompleted: @escaping (Bool, [FSPhotoInfo]) -> ()) {
        self.getAllPhotos(withDeleted: withDeleted, onCompleted: { (success, listPhotos) in
            if success == false {
                onCompleted(false, listPhotos)
                return
            }
            
            var result = [FSPhotoInfo]()
            for info in listPhotos {
                if options.bUserName == true && options.userid != nil {
                    if info.userid != options.userid {
                        continue
                    }
                }
                
                if options.bTakenDate == true && options.takenDateFrom != nil && options.takenDateTo != nil {
                    if info.taken < options.takenDateFrom! || info.taken > options.takenDateTo! {
                        continue
                    }
                }

                if options.bUploadDate == true && options.uploadDateFrom != nil && options.uploadDateTo != nil {
                    if info.uploaded < options.uploadDateFrom! || info.uploaded > options.uploadDateTo! {
                        continue
                    }
                }
                
                if options.bDeletedDate == true && options.deletedDateFrom != nil && options.deletedDateTo != nil {
                    if info.deletedTime < options.deletedDateFrom! || info.deletedTime > options.deletedDateTo! {
                        continue
                    }
                }
                
                result += [info]
            }

            onCompleted(true, result)
        })
    }
    
    static func getAllPhotos(withDeleted: Bool, onCompleted: @escaping (Bool, [FSPhotoInfo]) -> ()) {
        let db = Firestore.firestore()
        let refPhotos = db.collection("photos")

        // order by uploaded date DESC
        refPhotos.order(by: PhotoField.uploaded, descending: true).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting photos documents:\(err)")
                onCompleted(false, [])
            } else {
                var result = [FSPhotoInfo]()

                for document in querySnapshot!.documents {
                    let info = self.convertToPhotoInfo(document: document)
                    
                    // include deleted files
                    if withDeleted == false && info.deleted == true {
                        continue
                    } else {
                        // check validation
                        let data = document.data()
                        let valid = data["valid"] as! Bool
                        
                        if valid == true {
                            let info = self.convertToPhotoInfo(document: document)
                            result += [info]
                        }
                    }
                }
                
                // exclude delete file (for the check uploaded or downloaded)
                if withDeleted == false {
                    Global.sharedCloudPhotos = result
                }
                onCompleted(true, result)
            }
        }
    }
    
    static func searchPhoto(cloudDocumentID: String, onCompleted: @escaping (Bool, String?) -> ()) {
        let db = Firestore.firestore()

        db.collection("photos").document(cloudDocumentID).getDocument() { (document, error) in
            if let error = error {
                print("Error getting photos documents:\(error)")
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
                    print("Error getting photos documents:\(error)")
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
    
    static func registerPhoto(info: FSPhotoInfo, onCompleted: @escaping (Bool, String?) -> ()) {
        let data = [PhotoField.userid: info.userid,
            PhotoField.email: info.email,
            PhotoField.username: info.username,
            PhotoField.taken: info.taken,
            PhotoField.uploaded: info.uploaded,
            PhotoField.sourceType: info.sourceType.rawValue,
            PhotoField.sourceID: info.sourceID,
            PhotoField.sizeWidth: info.size.width,
            PhotoField.sizeHeight: info.size.height,
            PhotoField.location: info.location,
            PhotoField.tag: info.tag,
            PhotoField.valid: false,
            PhotoField.deleted: false,
            ] as [String : Any]

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
            PhotoField.valid: true
        ]) { err in
            if let err = err {
                debugPrint(err)
                
            } else {
                onCompleted(true)
            }
        }
    }
    
    static func deletePhoto(photoID: String, onCompleted: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()

        /*
        db.collection("photos").document(photoID).delete { (err) in
            if let err = err {
                debugPrint(err)
                onCompleted(false)
            } else {
                onCompleted(true)
            }
        }*/
        db.collection("photos").document(photoID).updateData([
            PhotoField.deleted: true,
            PhotoField.deletedTime: Date().timeIntervalSince1970
        ]) { err in
            if let err = err {
                debugPrint(err)
                
            } else {
                onCompleted(true)
            }
        }
    }
    
    static func convertToNotificationInfo(document: QueryDocumentSnapshot) -> FSNotificationInfo {
        let info = FSNotificationInfo()
        
        let data = document.data()
        
        info.id = document.documentID
        
        info.userid = (data[NotificationField.userid] as! String)
        info.email = (data[NotificationField.email] as! String)
        info.username = (data[NotificationField.username] as! String)

        let timestamp = data[NotificationField.timestamp]
        if timestamp is TimeInterval {
            info.timestamp = timestamp as! TimeInterval
        } else {
            info.timestamp = Date().timeIntervalSince1970
        }

        info.type = (data[NotificationField.type] as! Int)
        info.count = (data[NotificationField.count] as! Int)
        
        return info
    }
    
    static func getRecentNotifications(onCompleted: @escaping (Bool, [FSNotificationInfo]) -> ()) {
        let db = Firestore.firestore()
        let refPhotos = db.collection("notifications")
        
        let fromDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        let from = fromDate!.timeIntervalSince1970

        // order by timestamp DESC
        refPhotos.order(by: NotificationField.timestamp, descending: true)
            .whereField(NotificationField.timestamp, isGreaterThanOrEqualTo: from)
            .getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting notifications documents:\(err)")
                onCompleted(false, [])
            } else {
                var result = [FSNotificationInfo]()

                for document in querySnapshot!.documents {
                    let info = self.convertToNotificationInfo(document: document)
                    result += [info]
                }

                onCompleted(true, result)
            }
        }
    }
    
    static func registerNotification(info: FSNotificationInfo, onCompleted: @escaping (Bool, String?) -> ()) {
        let data = [NotificationField.userid: info.userid,
            NotificationField.email: info.email,
            NotificationField.username: info.username,
            NotificationField.timestamp: info.timestamp,
            NotificationField.type: info.type,
            NotificationField.count: info.count] as [String : Any]

        let db = Firestore.firestore()
        var ref: DocumentReference? = nil

        ref = db.collection("notifications").addDocument(data: data) { err in
            if let err = err {
                debugPrint(err)
                onCompleted(false, nil)
            } else {
                onCompleted(true, ref!.documentID)
            }
        }
    }
    
    // update user display name
    static func registerRPIFrame(ID: String, title: String, onCompleted: @escaping (Bool) -> ()) {
        guard let userid = Global.userid else { return }

        let db = Firestore.firestore()
        
        db.collection("users").document(userid).collection("frames").document(ID).setData([
            "title": title,
            "reg_time": Date().timeIntervalSince1970,
        ]) { err in
            if let err = err {
                debugPrint(err)
                onCompleted(false)
            } else {
                onCompleted(true)
            }
        }
    }
    
    static func getAllFrames(onCompleted: @escaping (Bool, [FSFrameInfo]) -> ()) {
        guard let userid = Global.userid else { return }
        
        let db = Firestore.firestore()
        let refPhotos = db.collection("users").document(userid).collection("frames")

        // order by uploaded date DESC
        refPhotos.getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting photos documents:\(err)")
                onCompleted(false, [])
            } else {
                var result = [FSFrameInfo]()

                for document in querySnapshot!.documents {
                    
                    let frame = FSFrameInfo()
                    let data = document.data()
                    
                    frame.frameid = document.documentID
                    frame.title = data["title"] as! String
                    frame.reg_time = data["reg_time"] as! TimeInterval
                    
                    result += [frame]
                }
                
                onCompleted(true, result)
            }
        }
    }
    
    // add photo to frame
    static func addPhotoToFrame(ID: String, photoID:String, onCompleted: @escaping (Bool) -> ()) {
        guard let userid = Global.userid else { return }

        let frameCollection = GFSModule.getCollectionNameOfFrame(ID: ID)
        let db = Firestore.firestore()
        
        db.collection(frameCollection).document(photoID).setData([
            FramePhotoField.regtime: Date().timeIntervalSince1970,
            FramePhotoField.userid: userid,
        ]) { err in
            if let err = err {
                debugPrint(err)
                onCompleted(false)
            } else {
                onCompleted(true)
            }
        }
    }
    
    static func convertToFramePhotoInfo(document: QueryDocumentSnapshot) -> FSFramePhotoInfo {
        let photoInfo = FSFramePhotoInfo()
        
        let data = document.data()
        
        photoInfo.id = document.documentID
        photoInfo.userid = (data[PhotoField.userid] as! String)
        
        let regtime = data[FramePhotoField.regtime]
        if regtime is TimeInterval {
            photoInfo.regtime = regtime as! TimeInterval
        } else {
            photoInfo.regtime = Date().timeIntervalSince1970
        }
        
        return photoInfo
    }
    
    static func getAllPhotosOfFrame(ID: String, onCompleted: @escaping (Bool, [FSFramePhotoInfo]) -> ()) {
        let db = Firestore.firestore()
        let frameCollection = GFSModule.getCollectionNameOfFrame(ID: ID)
        let refPhotos = db.collection(frameCollection)

        // order by uploaded date DESC
        refPhotos.order(by: FramePhotoField.regtime, descending: true).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting photos documents:\(err)")
                onCompleted(false, [])
            } else {
                var result = [FSFramePhotoInfo]()

                for document in querySnapshot!.documents {
                    let info = self.convertToFramePhotoInfo(document: document)
                    result += [info]
                }

                onCompleted(true, result)
            }
        }
    }
}

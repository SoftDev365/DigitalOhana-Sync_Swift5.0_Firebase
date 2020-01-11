//
//  SqliteManager.swift
//  SharePhoto
//
//  Created by Admin on 11/28/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import SQLite

class SqliteManager: NSObject {

    static let dbFileName = "sync.db"
    static var dbFilePath = ""
    
    static func open() -> Bool {
        do {

            //dbFilePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            //dbFilePath += "/" + dbFileName
            
            let fileManager = FileManager.default
            let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.al.ohanasync")
            dbFilePath = directory!.appendingPathComponent(dbFileName).absoluteString
            debugPrint("======= shared Path: \(dbFilePath)")
            
            let db = try Connection(dbFilePath)

            let tblPhotos = Table("photos")
            let fd_id = Expression<Int64>("id")
            let fd_mine = Expression<Bool>("mine")
            let fd_fname = Expression<String>("fname")
            let fd_fsid = Expression<String>("fs_id")
            let fd_sync = Expression<Bool>("sync")
            
            do {
                let bExists = try db.scalar(tblPhotos.exists)
                if bExists {
                    // exists
                    debugPrint("------sqlite db photos table already exists-------")
                }
            } catch {
                // don't exist
                try db.run(tblPhotos.create { t in
                    t.column(fd_id, primaryKey: true)
                    t.column(fd_mine)
                    t.column(fd_fname)
                    t.column(fd_fsid)
                    t.column(fd_sync, defaultValue: true)
                })
            }
        } catch let error {
            debugPrint(error)
            return false
        }

        return true
    }
    
    static func insertFileInfo(isMine:Bool, fname:String, fsID:String) -> Bool {
        do {
            let db = try Connection(dbFilePath)

            let users = Table("photos")
            //let fd_id = Expression<Int64>("id")
            let fd_mine = Expression<Bool>("mine")
            let fd_fname = Expression<String>("fname")
            let fd_fsid = Expression<String>("fs_id")
            let fd_sync = Expression<Bool>("sync")

            let insert = users.insert(fd_mine <- isMine, fd_fname <- fname, fd_fsid <- fsID, fd_sync <- true)
            //let rowid = try db.run(insert)
            try db.run(insert)
        } catch let error {
            print(error)
            return false
        }

        return true
    }
    
    static func checkPhotoIsUploaded(localIdentifier: String) -> Bool {
        do {
            let db = try Connection(dbFilePath)

            let photos = Table("photos")
            let fd_fname = Expression<String>("fname")
            let alice = photos.filter(fd_fname == localIdentifier)
            //db.prepare(photos.select([*]).filter)
            
            let count = try db.scalar(alice.count)
            if count > 0 {
                return true
            }
            /*
            let fd_id = Expression<Int64>("id")
            let fd_mine = Expression<Bool>("mine")
            for photo in try db.prepare(alice) {
                let file = ["id":photo[fd_id], "mine":photo[fd_mine], "fname": photo[fd_fname]] as [String : Any]
                debugPrint(file)
                return true
            }*/

            return false
        } catch let error {
            print(error)
            return false
        }
    }
    
    static func checkPhotoIsDownloaded(cloudFileID: String) -> Bool {
        do {
            let db = try Connection(dbFilePath)

            let photos = Table("photos")
            let fd_fsid = Expression<String>("fs_id")
            let alice = photos.filter(fd_fsid == cloudFileID)
            
            let count = try db.scalar(alice.count)
            if count > 0 {
                return true
            }

            return false
        } catch let error {
            print(error)
            return false
        }
    }

    static func getAllFileInfos() -> [[String:Any]] {
        do {
            let db = try Connection(dbFilePath)

            let photos = Table("photos")
            let fd_id = Expression<Int64>("id")
            let fd_mine = Expression<Bool>("mine")
            let fd_fname = Expression<String>("fname")
            let fd_fsid = Expression<String>("fs_id")
            let fd_sync = Expression<Bool>("sync")

            var arrFiles = [[String:Any]]()

            for photo in try db.prepare(photos) {
                let file = ["id":photo[fd_id], "mine":photo[fd_mine], "fname": photo[fd_fname], "fs_id": photo[fd_fsid], "sync": photo[fd_sync]] as [String : Any]
                arrFiles += [file]
            }
            
            return arrFiles
        } catch let error {
            print(error)
            return [[String:Any]]()
        }
    }
    
    static func syncFileInfos(arrFiles: [String]) {
        do {
            let db = try Connection(dbFilePath)

            let photos = Table("photos")
            //let fd_id = Expression<Int64>("id")
            //let fd_mine = Expression<Bool>("mine")
            let fd_fname = Expression<String>("fname")
            //let fd_fsid = Expression<String>("fs_id")
            let fd_sync = Expression<Bool>("sync")

            //try db.run(users.update(email <- email.replace("mac.com", with: "me.com")))
            try db.run(photos.update(fd_sync <- false))

            for file in arrFiles {
                let alice = photos.filter(fd_fname == file)
                try db.run(alice.update(fd_sync <- true))
            }
            
            //delete no exist files
            let alice = photos.filter(fd_sync == false)
            try db.run(alice.delete())
            
        } catch let error {
            print(error)
        }
    }
    
    static func deleteNoExistFiles() {
        do {
            let db = try Connection(dbFilePath)

            let photos = Table("photos")
            let fd_sync = Expression<Bool>("sync")
            
            let alice = photos.filter(fd_sync == false)

            try db.run(alice.delete())
        } catch let error {
            print(error)
        }
    }
    
    static func deletePhotoBy(cloudFileID: String) {
        do {
            let db = try Connection(dbFilePath)

            let photos = Table("photos")
            let fd_fsid = Expression<String>("fs_id")

            let alice = photos.filter(fd_fsid == cloudFileID)

            try db.run(alice.delete())
        } catch let error {
            print(error)
        }
    }
    
    /*
    static func all() -> Bool {
        do {
            let db = try Connection(dbFileName)

            let users = Table("users")
            let id = Expression<Int64>("id")
            let name = Expression<String?>("name")
            let email = Expression<String>("email")

            try db.run(users.create { t in
                t.column(id, primaryKey: true)
                t.column(name)
                t.column(email, unique: true)
            })
            
            // CREATE TABLE "users" (
            //     "id" INTEGER PRIMARY KEY NOT NULL,
            //     "name" TEXT,
            //     "email" TEXT NOT NULL UNIQUE
            // )
            
            let insert = users.insert(name <- "Alice", email <- "alice@mac.com")
                let rowid = try db.run(insert)
                // INSERT INTO "users" ("name", "email") VALUES ('Alice', 'alice@mac.com')

                for user in try db.prepare(users) {
                    print("id: \(user[id]), name: \(user[name]), email: \(user[email])")
                    // id: 1, name: Optional("Alice"), email: alice@mac.com
                }
                // SELECT * FROM "users"

                let alice = users.filter(id == rowid)
                try db.run(alice.update(email <- email.replace("mac.com", with: "me.com")))
                // UPDATE "users" SET "email" = replace("email", 'mac.com', 'me.com')
                // WHERE ("id" = 1)

                try db.run(alice.delete())
                // DELETE FROM "users" WHERE ("id" = 1)

                try db.scalar(users.count) // 0
                // SELECT count(*) FROM "users"

                let stmt = try db.prepare("INSERT INTO users (email) VALUES (?)")
                for email in ["betty@icloud.com", "cathy@icloud.com"] {
                    try stmt.run(email)
                }

                db.totalChanges    // 3
                db.changes         // 1
                db.lastInsertRowid // 3

                for row in try db.prepare("SELECT id, email FROM users") {
                    print("id: \(row[0]), email: \(row[1])")
                    // id: Optional(2), email: Optional("betty@icloud.com")
                    // id: Optional(3), email: Optional("cathy@icloud.com")
                }

                try db.scalar("SELECT count(*) FROM users") // 2
        } catch let error {
            print(error)
            return false
        }

        return true
    }*/
}

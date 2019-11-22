//
//  GUser.swift
//  Google User
//
//  Created by Admin on 11/6/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

class GUser: NSObject {
    static var user: GIDGoogleUser?
    static var email: String?
}

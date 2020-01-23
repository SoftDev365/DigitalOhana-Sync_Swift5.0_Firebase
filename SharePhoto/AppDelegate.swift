//
//  AppDelegate.swift
//  SharePhoto
//
//  Created by Admin on 11/5/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import HelpCrunchSDK

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // for the simulator
        //UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        UINavigationBar.appearance().tintColor = UIColor.white
        
        // Override point for customization after application launch.
        FirebaseApp.configure()

        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().shouldFetchBasicProfile = true

        if( SqliteManager.open() ) {
            let files = SqliteManager.getAllFileInfos()
            debugPrint("----db open success------")
            debugPrint(files)
        } else {
            debugPrint("----db open fail------")
        }
        
        let configuration = HCSConfiguration(forOrganization: "leruthstech",
                                                 applicationId: "3",
                                                 applicationSecret: "ARfN5+9unBuWonwaXN9Cg+uLxEAg7BhD1lFYLLTL7yzirgdGIhsioQqgXnTHQGQh65dizk/JdzLozZ5SbxgaGA==")
        
        configuration.shouldUsePushNotificationDelegate = true
        setupPrechatFormScreen(configuration: configuration)
        
        HelpCrunch.initWith(configuration, user: nil) { (error) in
            // Do something on SDK init completion
            if error == nil {
                debugPrint("HelpCruch init success")
                Global.helpCrunchInited = true
                HCModule.updateHelpCrunchUserInfo()
            } else {
                debugPrint("HelpCruch init fail \(error!)")
            }
        }

        HelpCrunch.registerForRemoteNotifications()
        if (!HelpCrunch.didReceiveRemoteNotification(launchOptions: launchOptions)) {
            // this push notification does not belong to HelpCrunch
        }
        
        return true
    }
    
    func setupPrechatFormScreen(configuration: HCSConfiguration) {
        configuration.userAttributes = [HCSUserAttribute.nameAttribute(asRequired: false),
                                        HCSUserAttribute.emailAttribute(asRequired: false)]
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let sourceApplication = options[.sourceApplication] as? String
        let annotation = options[.annotation]
        
        return GIDSignIn.sharedInstance()?.handle(url, sourceApplication: sourceApplication, annotation: annotation) ?? false
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        HelpCrunch.setDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        if (!HelpCrunch.didReceiveRemoteNotification(userInfo)) {
            // this push notification does not belong to HelpCrunch
        }
    }
}

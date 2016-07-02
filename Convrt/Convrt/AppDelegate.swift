//
//  AppDelegate.swift
//  Convrt
//
//  Created by Hamon Riazy on 16/05/15.
//  Copyright (c) 2015 ryce. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    // MARK: Core Data Helper
        
    // MARK: 3D Touch
    
    @available(iOS 9.0, *)
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        print("shortcut call")
        if shortcutItem.type == "com.ryce.convrt.openhundredeur" {
            guard let viewController = self.window?.rootViewController as? ViewController,
                let shortcutCurrency = shortcutItem.userInfo?["currency"] as? String,
                let currency = viewController.convrtSession.selectedCurrencies.filter({ $0.code == shortcutCurrency }).first,
                let shortcutAmount = shortcutItem.userInfo?["amount"] as? String,
                let currentAmount = Double(shortcutAmount) else {
                completionHandler(false)
                return
            }
            
            viewController.updateView(currentAmount, currency: currency)
            
        }
        completionHandler(true)
    }


}


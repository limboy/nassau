//
//  AppDelegate.swift
//  Nassau
//
//  Created by limboy on 07/11/2017.
//  Copyright © 2017 limboy. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var adbPath:String {
        get {
            let defaultPath = "~/Library/Android/sdk/platform-tools/adb"
            let storedPath = UserDefaults.standard.string(forKey: "adbpath")
            return storedPath == nil ? defaultPath : storedPath!
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "adbpath")
            UserDefaults.standard.synchronize()
        }
    }
    
    var adbKeyword: String = ""

    let mainWindowController = MainWindowController()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        mainWindowController.startup()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}


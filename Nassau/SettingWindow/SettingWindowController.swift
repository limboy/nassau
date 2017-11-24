//
//  SettingWindowController.swift
//  Nassau
//
//  Created by limboy on 14/11/2017.
//  Copyright © 2017 limboy. All rights reserved.
//

import Cocoa

class SettingWindowController: NSWindowController {
    
    static var defaultRect = {
        return NSMakeRect(0, 0, 480, 160)
    }()
    
    init() {
        let window = NSWindow()
        window.titleVisibility = .visible
        window.styleMask = [.closable, .miniaturizable, .titled]

        let width = SettingWindowController.defaultRect.size.width
        let height = SettingWindowController.defaultRect.size.height
        let x = (NSScreen.main?.frame.size.width)! / 2 - width / 2
        let y = (NSScreen.main?.frame.size.height)! / 2 - height / 2
        
        window.setFrame(NSMakeRect(x, y, width, height), display: false)
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        window?.contentViewController = SettingViewController()
    }
    
}

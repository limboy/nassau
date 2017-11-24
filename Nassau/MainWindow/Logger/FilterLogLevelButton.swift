//
//  FilterLogLevelButton.swift
//  Nassau
//
//  Created by limboy on 10/11/2017.
//  Copyright © 2017 limboy. All rights reserved.
//

import Cocoa

class FilterLogLevelButton: NSButton {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setButtonType(.pushOnPushOff)
        // self.isBordered = false
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}

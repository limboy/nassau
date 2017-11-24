//
//  LogLevelView.swift
//  Nassau
//
//  Created by limboy on 21/11/2017.
//  Copyright © 2017 limboy. All rights reserved.
//

import Cocoa

class LogLevelView: NSTextView {
    
    private var hasClickedDown = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.wantsLayer = true
        self.isSelectable = false
        self.isEditable = false
        self.backgroundColor = NSColor.white
        self.textContainerInset = NSMakeSize(0, 5)
        self.layer?.cornerRadius = 2
        self.textColor = NSColor.black
        self.alignment = .center
    }
    
    var clickHandler: ((LogLevelView) -> Void)?
    
    func deSelect() {
        self.backgroundColor = NSColor.white
        self.textColor = NSColor.black
        hasClickedDown = false
    }
    
    func select() {
        self.textColor = NSColor.white
        self.backgroundColor = NSColor(calibratedRed: 39/255.0, green: 134/255.0, blue: 243/255.0, alpha: 1)
        hasClickedDown = true
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func mouseDown(with event: NSEvent) {
        select()
    }
    
    override func mouseEntered(with event: NSEvent) {
        if (!hasClickedDown) {
            self.textColor = NSColor.white
            self.backgroundColor = NSColor(calibratedRed: 147/255.0, green: 195/255.0, blue: 249/255.0, alpha: 1)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if (!hasClickedDown) {
            self.textColor = NSColor.black
            self.backgroundColor = NSColor.white
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        clickHandler?(self)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}

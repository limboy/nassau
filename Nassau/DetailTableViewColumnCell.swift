//
//  DetailTableViewColumnCell.swift
//  Nassau
//
//  Created by limboy on 10/11/2017.
//  Copyright © 2017 limboy. All rights reserved.
//

import Cocoa

class DetailTableViewColumnCell: NSTableCellView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(aTextField)
        
        aTextField.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        aTextField.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        aTextField.topAnchor.constraint(equalTo: topAnchor, constant: 3).isActive = true
        aTextField.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError()
    }

    lazy var aTextField:NSTextField = {
        let t = NSTextField()
        t.wantsLayer = true
        t.isBordered = false
        t.focusRingType = .none
        t.isEditable = false
        t.isSelectable = true
        // t.cell?.usesSingleLineMode = true
        t.cell?.wraps = true
        // t.cell?.lineBreakMode = .byWordWrapping
        // t.cell?.isScrollable = true
        t.cell?.truncatesLastVisibleLine = true
        t.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()
    
    func configure(text:String, level: LogLevel) {
        aTextField.stringValue = text
        if (level == .error) {
            aTextField.textColor = NSColor.red
        } else if (level == .warn) {
            aTextField.textColor = NSColor(calibratedRed: 1.0, green: 160/255.0, blue: 0, alpha: 1)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}

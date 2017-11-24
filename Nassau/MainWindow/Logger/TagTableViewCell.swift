//
//  TagTableViewCell.swift
//  Nassau
//
//  Created by limboy on 09/11/2017.
//  Copyright © 2017 limboy. All rights reserved.
//

import Cocoa

class TagTableViewCell: NSTableCellView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        buildUI()
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError()
    }
    
    private lazy var label: NSTextField = {
        var t = NSTextField(labelWithString: "")
        t.font = .systemFont(ofSize: 14)
        t.textColor = NSColor.black
        return t
    }()
    
    private lazy var countLabel: NSTextField = {
        var t = NSTextField(labelWithString: "")
        t.wantsLayer = true
        t.isEditable = false
        t.font = .systemFont(ofSize: 14)
        t.textColor = NSColor.lightGray
        return t
    }()
    
    private func buildUI() {
        addSubview(label)
        addSubview(countLabel)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7).isActive = true
        label.topAnchor.constraint(equalTo: topAnchor, constant: 7).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 7).isActive = true
        
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 5).isActive = true
        countLabel.topAnchor.constraint(equalTo: topAnchor, constant: 7).isActive = true
        countLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 7).isActive = true
    }

    func configure(tagName: String, tagCount: Int) {
        label.stringValue = tagName
        countLabel.stringValue = "(" + String(tagCount) + ")"
    }
}

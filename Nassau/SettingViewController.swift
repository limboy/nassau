//
//  SettingViewController.swift
//  Nassau
//
//  Created by limboy on 14/11/2017.
//  Copyright © 2017 limboy. All rights reserved.
//

import Cocoa

class SettingViewController: NSViewController, NSTextFieldDelegate {

    lazy var adbTitleTextField:NSTextField = {
        var v = NSTextField()
        v.isBordered = false
        v.frame = NSMakeRect(20, 77, 90, 22)
        v.stringValue = "ADB Path"
        v.isEditable = false
        v.isSelectable = false
        v.alignment = .right
        return v
    }()
    
    lazy var adbTextField:NSTextField = {
        var v = NSTextField()
        v.frame = NSMakeRect(120, 80, 320, 22)
        v.usesSingleLineMode = true
        v.cell?.wraps = true
        v.cell?.isScrollable = true
        v.focusRingType = .none
        
        v.stringValue = (NSApplication.shared.delegate as! AppDelegate).adbPath
        v.currentEditor()?.selectedRange = NSMakeRange(0, 0)
        
        return v
    }()
    
    lazy var keywordTextField: NSTextField = {
        var v = NSTextField()
        v.frame = NSMakeRect(120, 113, 320, 22)
        v.usesSingleLineMode = true
        v.cell?.wraps = true
        v.cell?.isScrollable = true
        v.focusRingType = .none
        v.stringValue = (NSApplication.shared.delegate as! AppDelegate).adbKeyword
        v.placeholderString = "设置之后将展示这个关键字相关的日志"
        
        v.currentEditor()?.selectedRange = NSMakeRange(0, 0)
        
        return v
    }()
    
    lazy var keywordTitleTextField:NSTextField = {
        var v = NSTextField()
        v.isBordered = false
        v.frame = NSMakeRect(20, 110, 90, 22)
        v.stringValue = "ADB Keyword"
        v.isEditable = false
        v.isSelectable = false
        v.alignment = .right
        return v
    }()

    override func loadView() {
        let width = SettingWindowController.defaultRect.size.width
        let height = SettingWindowController.defaultRect.size.height
        let x = (NSScreen.main?.frame.size.width)! / 2 - width / 2
        let y = (NSScreen.main?.frame.size.height)! / 2 - height / 2
        self.view = NSView(frame: NSMakeRect(x,
                                             y,
                                             width,
                                             height))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.addSubview(adbTitleTextField)
        view.addSubview(adbTextField)
        view.addSubview(keywordTextField)
        view.addSubview(keywordTitleTextField)
        
        adbTextField.delegate = self
        keywordTextField.delegate = self
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(insertNewline(_:))) {
            if control == adbTextField {
                (NSApplication.shared.delegate as! AppDelegate).adbPath = textView.string
            } else if control == keywordTextField {
                (NSApplication.shared.delegate as! AppDelegate).adbKeyword = textView.string
            }
            return true
        }
        return false
    }
}

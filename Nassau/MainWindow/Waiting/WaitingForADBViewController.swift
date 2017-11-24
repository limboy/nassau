//
//  WaitingForADBViewController.swift
//  Nassau
//
//  Created by limboy on 11/11/2017.
//  Copyright © 2017 limboy. All rights reserved.
//

import Cocoa

// MARK: Properties
class WaitingForADBViewController: NSViewController {
    private var windowController: MainWindowController?
    
    private lazy var waitingImageView: NSImageView = {
        let v = NSImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        let image = NSImage(named: NSImage.Name(rawValue: "wait4adb"))
        v.image = image
        return v
    }()
    
    private lazy var changeADBTitle: NSTextField = {
        let v = NSTextField()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isEditable = false
        v.isSelectable = false
        v.isBordered = false
        v.backgroundColor = NSColor.clear
        v.stringValue = "adb command not found, change path in 'Preferences...'"
        v.font = .systemFont(ofSize: 14)
        v.textColor = NSColor.gray
        v.isHidden = true
        
        return v
    }()
    
    init(windowController: MainWindowController) {
        super.init(nibName: nil, bundle: nil)
        self.windowController = windowController
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}

// MARK: Life Cycle
extension WaitingForADBViewController {
    override func loadView() {
        var frame = MainWindowController.defaultRect
        if self.windowController?.window?.screen != nil {
            frame = self.windowController!.window!.frame
        }
        self.view = NSView(frame: frame)
        view.addSubview(waitingImageView)
        waitingImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        waitingImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        view.addSubview(changeADBTitle)
        changeADBTitle.topAnchor.constraint(equalTo: waitingImageView.bottomAnchor, constant: 15).isActive = true
        changeADBTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
}

// MARK: Public Methods
extension WaitingForADBViewController {
    func showChangeADBPath() {
        changeADBTitle.isHidden = false
    }
    
    func hideChangeADBPath() {
        changeADBTitle.isHidden = true
    }
}

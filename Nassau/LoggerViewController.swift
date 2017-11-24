//
//  LoggerViewController.swift
//  Nassau
//
//  Created by limboy on 08/11/2017.
//  Copyright © 2017 limboy. All rights reserved.
//

import Cocoa

class LoggerViewController: NSSplitViewController {
    
    private var tagViewController: TagViewController
    private var detailViewController: DetailViewController
    private let windowController: MainWindowController
    private var logData: Dictionary = [String:Array<LogItem>]()
    private var topView:NSView?
    private var topViewZeroHeightConstraint: NSLayoutConstraint?
    private var topViewNormalHeightConstraint: NSLayoutConstraint?
    private var commandsBoxData: [[String:String]] = []
    private var selectedCommandKey: String?
    
    var commands: [[String:String]]? {
        didSet {
            DispatchQueue.main.async {
                self.showTopView()
                self.commandsBoxData = self.commands!
                self.commandsBox.reloadData()
                self.commandsBox.selectItem(at: 0)
            }
        }
    }
    
    private lazy var commandsBox: NSComboBox = {
        let c = NSComboBox()
        c.translatesAutoresizingMaskIntoConstraints = false
        c.usesDataSource = true
        c.dataSource = self
        c.delegate = self
        c.focusRingType = .none
        c.isEditable = false
        c.isHidden = true

        return c
    }()
    
    private lazy var commandTextField: NSTextField = {
        let v = NSTextField()
        v.focusRingType = .none
        v.cell?.usesSingleLineMode = true
        v.cell?.isScrollable = true
        v.translatesAutoresizingMaskIntoConstraints = false
        v.delegate = self
        v.isHidden = true
        
        return v
    }()
    
    private var selectedTags: [String]? {
        didSet {
            if let selectedTags = selectedTags {
                DispatchQueue.global().async {
                    var combined = [LogItem]()
                    selectedTags.forEach { (selectedTag) in
                        combined.append(contentsOf: self.logData[selectedTag]!)
                    }
                    combined = combined.sorted(by: { (item1, item2) -> Bool in
                        return item1.timestamp < item2.timestamp
                    })
                    
                    self.detailViewController.add(messages: combined)
                }
            }
        }
    }
    
    private lazy var dateFormatter:DateFormatter = {
        let d = DateFormatter()
        d.dateFormat = "HH:mm:ss.SSS"
        
        return d
    }()
    
    private func setupTopView() {
        topView = NSView()
        let superView = splitView.superview!
        topView!.translatesAutoresizingMaskIntoConstraints = false
        topView!.wantsLayer = true
        topView!.layer?.backgroundColor = NSColor(calibratedRed: 249/255.0, green: 249/255.0, blue: 250/255.0, alpha: 1).cgColor
        superView.addSubview(topView!)
        
        topViewZeroHeightConstraint = topView!.heightAnchor.constraint(equalToConstant: 0)
        topViewNormalHeightConstraint = topView!.heightAnchor.constraint(equalToConstant: 37)
        
        topView!.topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        topViewZeroHeightConstraint!.isActive = true
        topView!.leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        topView!.widthAnchor.constraint(equalTo: superView.widthAnchor).isActive = true
        
        let border = NSView()
        border.translatesAutoresizingMaskIntoConstraints = false
        topView?.addSubview(border)
        border.wantsLayer = true
        border.layer?.backgroundColor = NSColor.lightGray.cgColor
        border.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        border.bottomAnchor.constraint(equalTo: topView!.bottomAnchor, constant: 0).isActive = true
        border.leadingAnchor.constraint(equalTo: topView!.leadingAnchor).isActive = true
        border.widthAnchor.constraint(equalTo: topView!.widthAnchor).isActive = true
    }
    
    private func setupCommandsInTopView() {
        topView?.addSubview(commandsBox)
        topView?.addSubview(commandTextField)
        
        commandsBox.leadingAnchor.constraint(equalTo: topView!.leadingAnchor, constant: 8).isActive = true
        commandsBox.topAnchor.constraint(equalTo: topView!.topAnchor, constant: 8).isActive = true
        commandsBox.widthAnchor.constraint(equalToConstant: 100).isActive = true
        commandsBox.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        commandTextField.leadingAnchor.constraint(equalTo: commandsBox.trailingAnchor, constant: 10).isActive = true
        commandTextField.topAnchor.constraint(equalTo: topView!.topAnchor, constant: 8).isActive = true
        commandTextField.trailingAnchor.constraint(equalTo: topView!.trailingAnchor, constant: -8).isActive = true
        commandTextField.heightAnchor.constraint(equalToConstant: 21).isActive = true
    }
    
    private func showTopView() {
        topViewZeroHeightConstraint?.isActive = false
        topViewNormalHeightConstraint?.isActive = true
        commandsBox.isHidden = false
        commandTextField.isHidden = false
    }
    
    private func hideTopView() {
        topViewNormalHeightConstraint?.isActive = false
        topViewZeroHeightConstraint?.isActive = true
        commandsBox.isHidden = true
        commandTextField.isHidden = true
    }

    init(windowController: MainWindowController) {
        tagViewController = TagViewController(windowController:windowController)
        detailViewController = DetailViewController(windowController:windowController)
        self.windowController = windowController
        super.init(nibName: nil, bundle: nil)
        windowController.addLogObserver(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        
        setupTopView()
        setupCommandsInTopView()
        
        splitView.topAnchor.constraint(equalTo: topView!.bottomAnchor, constant: -1).isActive = true
        
        var frame = MainWindowController.defaultRect
        if self.windowController.window?.screen != nil {
            frame = self.windowController.window!.frame
        }
        view.frame = frame
        
        let listItem = NSSplitViewItem(sidebarWithViewController: tagViewController)
        listItem.canCollapse = false
        let detailItem = NSSplitViewItem(viewController: detailViewController)

        addSplitViewItem(listItem)
        addSplitViewItem(detailItem)

        tagViewController.view.setContentHuggingPriority(NSLayoutConstraint.Priority.defaultHigh, for: .horizontal)
        detailViewController.view.setContentHuggingPriority(NSLayoutConstraint.Priority.defaultLow, for: .horizontal)
        tagViewController.delegate = self
        detailViewController.delegate = self
        
        // simulate()
    }
    
    private func simulate() {
        add(log: LogItem(tag: "Image", level: .debug, date: "12:34", timestamp: 123.0, message: "Foo"))
        add(log: LogItem(tag: "Image", level: .info, date: "12:35", timestamp: 124.0, message: "Bar"))
        add(log: LogItem(tag: "com.mogujie", level: .info, date: "12:36", timestamp: 125.0, message: "Hello"))

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(4000)) {
            let str = "I'm a very long string, you have to scroll as hard as you can to see my end, but i won't tell you a story which i made myself, ha~\nI'm a very long string, you have to scroll as hard as you can to see my end, but i won't tell you a story which i made myself, ha~"
            self.add(log: LogItem(tag: "com.mogujie", level: .error, date: "12:38", timestamp: 126.0, message: str))
        }
    }
}

// MARK: Public
extension LoggerViewController {
    func clear() {
        selectedTags = nil
        hideTopView()
        logData.removeAll()
        tagViewController.clear()
        detailViewController.clear()
    }
}

extension LoggerViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(insertNewline(_:))) {
            let adbPath = (NSApplication.shared.delegate as! AppDelegate).adbPath
            let selectedCommandKey = self.selectedCommandKey!
            let commandValue = textView.string
            DispatchQueue.global().async {
                let _ = try! Shell().outputOf(commandName: adbPath, arguments: ["shell", "am", "broadcast", "-a", "nassau.REQUEST", "--es", selectedCommandKey, commandValue])
            }
            return true
        }
        return false
    }
}

extension LoggerViewController: NSComboBoxDelegate, NSComboBoxDataSource {
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        let dict = commandsBoxData[index]
        return dict["commandName"] ?? "Key not Found"
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return commandsBoxData.count
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let comboBox = notification.object as! NSComboBox
        let selectedIndex = comboBox.indexOfSelectedItem
        selectedCommandKey = commandsBoxData[selectedIndex]["commandKey"]
    }
}

extension LoggerViewController: LogDataObserverProtocol {
    func add(log: LogItem) {
        DispatchQueue.main.async {
            // tagVC 内部会处理掉重复的逻辑，同时统计次数
            self.tagViewController.append(tag: log.tag)

            if (!self.logData.keys.contains(log.tag)) {
                self.logData.updateValue([LogItem](), forKey: log.tag)
            }

            var list: Array = self.logData[log.tag]!
            list.append(log)

            self.logData[log.tag] = list

            if let selectedTags = self.selectedTags {
                if (selectedTags.contains(log.tag)) {
                    self.detailViewController.add(log: log)
                }
            }
        }
    }
    
    func onWindowResize() {
        detailViewController.reload()
    }
}

extension LoggerViewController: TagViewControllerDelegate {
    func didSelect(tags: [String]) {
        selectedTags = tags
    }
}

extension LoggerViewController: DetailViewControllerDelegate {
    func didClear() {
        if let selectedTags = selectedTags {
            selectedTags.forEach({ (selectedTag) in
                self.logData.updateValue([LogItem](), forKey: selectedTag)
                tagViewController.clear(tag: selectedTag)
            })
        }
    }
}

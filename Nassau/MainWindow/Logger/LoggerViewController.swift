//
//  LoggerViewController.swift
//  Nassau
//
//  Created by limboy on 08/11/2017.
//  Copyright © 2017 limboy. All rights reserved.
//

import Cocoa

// Private Properties
class LoggerViewController: NSSplitViewController {
    private var tagViewController: TagViewController
    private var detailViewController: DetailViewController
    private let windowController: MainWindowController
    private var logData: Dictionary = [String:Array<LogItem>]()
    private var topViewZeroHeightConstraint: NSLayoutConstraint?
    private var topViewNormalHeightConstraint: NSLayoutConstraint?
    
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
}

// MARK: Life Cycle
extension LoggerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        
        splitView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
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
}

// MARK: Private Methods
extension LoggerViewController {
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

// MARK: Public Methods
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
    
    func clear() {
        selectedTags = nil
        logData.removeAll()
        tagViewController.clear()
        detailViewController.clear()
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

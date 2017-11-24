//
//  TagViewController.swift
//  Nassau
//
//  Created by limboy on 08/11/2017.
//  Copyright © 2017 limboy. All rights reserved.
//

import Cocoa

protocol TagViewControllerDelegate {
    func didSelect(tags: [String])
}

class TagViewController: NSViewController {

    // MARK: Private Variables
    private struct Metrics {
        static let rowHeight:CGFloat = 32
    }
    
    private var isPrgramaticallyChangingSelection = false
    
    private var allTags = [String]()
    
    private var filteredTags = [String]()
    
    private var filteringKeyword = ""
    
    private var tagsCount = [String: Int]()
    
    private let windowController: MainWindowController
    
    private var tobeProcessedTags = Set<String>()

    private lazy var scrollView: NSScrollView = {
        let v = NSScrollView()
        v.focusRingType = .none
        v.documentView = self.tableView
        v.borderType = .noBorder
        v.hasVerticalScroller = true
        v.hasHorizontalScroller = false
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    private lazy var tableView: NSTableView = {
        let v = NSTableView()
        
        v.allowsMultipleSelection = true
        v.wantsLayer = true
        v.headerView = nil
        v.focusRingType = .none
        v.allowsEmptySelection = true
        v.backgroundColor = NSColor(calibratedRed: 246/255.0, green: 246/255.0, blue: 246/255.0, alpha: 1)
        v.rowHeight = Metrics.rowHeight
        v.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
        v.action = #selector(onItemClicked)
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "tag"))
        v.addTableColumn(column)
        
        return v
    }()
    
    private lazy var textField: NSTextField = {
        var textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.focusRingType = .none
        textField.font = .systemFont(ofSize: 14)
        textField.wantsLayer = true
        textField.layer?.borderColor = NSColor(calibratedRed: 186/255.0, green: 186/255.0, blue: 186/255.0, alpha: 1).cgColor
        textField.layer?.borderWidth = 1
        textField.layer?.cornerRadius = 2
        textField.placeholderString = "Filter Tag"
        textField.cell?.usesSingleLineMode = true
        textField.delegate = self
        
        return textField
    }()
    
    private lazy var filterSection: NSView = {
        var v = NSView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.white.cgColor

        let separator = NSView()
        v.addSubview(separator)
        separator.wantsLayer = true
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.layer?.backgroundColor = NSColor(calibratedRed: 223/255.0, green: 223/255.0, blue: 223/255.0, alpha: 1).cgColor
        separator.widthAnchor.constraint(equalTo: v.widthAnchor).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.topAnchor.constraint(equalTo: v.topAnchor).isActive = true
        separator.leadingAnchor.constraint(equalTo: v.leadingAnchor).isActive = true
        
        return v
    }()
    
    private func processAddedTags() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.processAddedTags()
        }
        
        if (tobeProcessedTags.count <= 0) {
            return
        }
        
        tobeProcessedTags.forEach { (tag) in
            // 如果正在过滤，且没有命中
            var shouldReload = true
            if filteringKeyword != "" && tag.lowercased().range(of: filteringKeyword.lowercased()) == nil{
                shouldReload = false
            }
            
            if !allTags.contains(tag) {
                allTags.append(tag)
            }
            
            if shouldReload {
                if !filteredTags.contains(tag) {
                    self.tableView.beginUpdates()
                    let addedIndex = IndexSet(integer: filteredTags.count)
                    self.tableView.insertRows(at: addedIndex, withAnimation: .slideDown)
                    filteredTags.append(tag)
                    tableView.reloadData(forRowIndexes: addedIndex, columnIndexes: IndexSet(integersIn: 0..<1))
                    self.tableView.endUpdates()
                } else {
                    let index = filteredTags.index(of: tag)
                    let reloadIndex = IndexSet(integer: index!)
                    // 去掉这个应该也 OK
                    // tableView.moveRow(at: index!, to: index!)
                    tableView.reloadData(forRowIndexes: reloadIndex, columnIndexes: IndexSet(integersIn:0..<1))
                }
            }
        }
        
        tobeProcessedTags.removeAll()
    }
    
    // MARK: Public Variables
    var delegate: TagViewControllerDelegate?

    @objc func onItemClicked() {
        let selected = tableView.clickedRow
        if (selected != -1) {
            var selectedTags = [String]()
            tableView.selectedRowIndexes.forEach({ (index) in
                selectedTags.append(self.filteredTags[index])
            })
            delegate?.didSelect(tags: selectedTags)
        }
    }

    // MARK: Life Cycle
    init(windowController: MainWindowController) {
        self.windowController = windowController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0,
                                    y: 0,
                                width: 200,
                                height: MainWindowController.defaultRect.height))
        view.widthAnchor.constraint(lessThanOrEqualToConstant: 400).isActive = true
        
        scrollView.frame = view.bounds
        tableView.frame = view.bounds
        view.addSubview(scrollView)
        view.addSubview(filterSection)
        filterSection.addSubview(textField)
        
        filterSection.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        filterSection.heightAnchor.constraint(equalToConstant: 40).isActive = true
        filterSection.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        filterSection.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: filterSection.topAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        textField.centerXAnchor.constraint(equalTo: filterSection.centerXAnchor).isActive = true
        textField.centerYAnchor.constraint(equalTo: filterSection.centerYAnchor).isActive = true
        textField.widthAnchor.constraint(equalTo: filterSection.widthAnchor, constant: -16).isActive = true
        textField.heightAnchor.constraint(equalTo: filterSection.heightAnchor, constant: -16).isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        //view.wantsLayer = true
        //view.layer?.backgroundColor = NSColor.darkGray.cgColor
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.reloadData()
        
        processAddedTags()
    }
}

// MARK: Public
extension TagViewController {
    func append(tag: String) {
        if !tagsCount.keys.contains(tag) {
            tagsCount[tag] = 0
        }
        tagsCount[tag] = tagsCount[tag]! + 1

        reload(tag: tag)
    }
    
    func reload(tag: String) {
        tobeProcessedTags.insert(tag)
    }
    
    func clear() {
        filteringKeyword = ""
        textField.stringValue = ""
        tobeProcessedTags.removeAll()
        allTags.removeAll()
        filteredTags.removeAll()
        tagsCount.removeAll()
        tableView.reloadData()
    }
    
    func clear(tag: String) {
        tagsCount[tag] = 0
        reload(tag: tag)
    }
}

extension TagViewController: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField
        filteringKeyword = textField.stringValue
        filteredTags = allTags.filter({ (tag) -> Bool in
            return filteringKeyword == "" || tag.lowercased().range(of: self.filteringKeyword.lowercased()) != nil
        })
        tableView.reloadData()
    }
}

extension TagViewController: NSTableViewDelegate, NSTableViewDataSource {
    private struct Constants {
        static let rowIdentifier = "row"
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredTags.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tag"), owner: nil) as? TagTableViewCell
        
        if cell == nil {
            cell = TagTableViewCell(frame: .zero)
            cell?.identifier = NSUserInterfaceItemIdentifier(rawValue: "tag")
        }
        
        cell?.configure(tagName: filteredTags[row], tagCount: tagsCount[filteredTags[row]]!)
        
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selected = tableView.selectedRowIndexes

        var tags = [String]()
        for (_, item) in selected.enumerated() {
            tags.append(filteredTags[item])
        }

        delegate?.didSelect(tags: tags)
    }
}

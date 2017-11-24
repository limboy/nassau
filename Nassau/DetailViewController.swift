//
//  DetailViewController.swift
//  Nassau
//
//  Created by limboy on 08/11/2017.
//  Copyright © 2017 limboy. All rights reserved.
//

import Cocoa

protocol DetailViewControllerDelegate {
    func didClear()
}

class DetailViewController: NSViewController {
    
    private let windowController: MainWindowController
    
    private var filterText = ""
    
    private var selectedLogLevel: LogLevel?
    
    private lazy var dateFormatter:DateFormatter = {
        let d = DateFormatter()
        d.dateFormat = "HH:mm:ss.SSS"
        
        return d
    }()

    private struct Metrics {
        static let rowHeight:CGFloat = 24
    }

    private var allMessages = [LogItem]()
    
    private var filteredMessages = [LogItem]()
    
    private var messageColumn: NSTableColumn?
    
    private var shouldAutoScroll = true
    
    private var singleLineOfMessage = false
    
    private var tobeProcessedLogs = [LogItem]()

    lazy var scrollView: NSScrollView = {
        let v = NSScrollView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.white.cgColor
        v.focusRingType = .none
        v.documentView = self.tableView
        v.borderType = .noBorder
        v.hasVerticalScroller = true
        v.hasHorizontalScroller = false
        v.translatesAutoresizingMaskIntoConstraints = false

        return v
    }()

    lazy var tableView: NSTableView = {
        let v = NSTableView()

        v.allowsEmptySelection = true
        v.wantsLayer = true
        v.focusRingType = .none
        v.allowsEmptySelection = false
        v.backgroundColor = NSColor.white
        v.rowHeight = Metrics.rowHeight
        v.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
        v.selectionHighlightStyle = .none
        v.gridColor = NSColor(calibratedRed: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1)
        v.gridStyleMask = NSTableView.GridLineStyle.solidHorizontalGridLineMask
        
        return v
    }()
    
    lazy var operationBar: NSView = {
        var o = NSView()
        o.translatesAutoresizingMaskIntoConstraints = false
        o.wantsLayer = true

        return o
    }()
    
    lazy var filterTextField: NSTextField = {
        var f = NSTextField()
        f.translatesAutoresizingMaskIntoConstraints = false
        f.font = .systemFont(ofSize: 14)
        f.focusRingType = .none
        f.wantsLayer = true
        f.layer?.borderColor = NSColor(calibratedRed: 186/255.0, green: 186/255.0, blue: 186/255.0, alpha: 1).cgColor
        f.layer?.borderWidth = 1
        f.layer?.cornerRadius = 2
        f.placeholderString = "Filter"
        return f
    }()
    
    lazy var separator: NSView = {
        let border = NSView()
        border.wantsLayer = true
        border.layer?.backgroundColor = NSColor(calibratedRed: 223/255.0, green: 223/255.0, blue: 223/255.0, alpha: 1).cgColor
        border.translatesAutoresizingMaskIntoConstraints = false
        
        return border
    }()
    
    lazy var etcItems: NSView = {
        let v = NSView()
        v.translatesAutoresizingMaskIntoConstraints = false
        
        let clearBtn = NSButton(title: "Clear", target: self, action: #selector(onClearBtnTapped(sender:)))
        clearBtn.setButtonType(.momentaryPushIn)
        v.addSubview(clearBtn)
        clearBtn.translatesAutoresizingMaskIntoConstraints = false
        
        clearBtn.leadingAnchor.constraint(equalTo: v.leadingAnchor).isActive = true
        clearBtn.topAnchor.constraint(equalTo: v.topAnchor, constant: 6).isActive = true
        
        let scrollBtn = NSButton(title: "PauseScroll", target: self, action: #selector(onScrollPauseBtnTapped(sender:)))
        scrollBtn.setButtonType(.pushOnPushOff)
        v.addSubview(scrollBtn)
        scrollBtn.translatesAutoresizingMaskIntoConstraints = false
        
        scrollBtn.leadingAnchor.constraint(equalTo: clearBtn.trailingAnchor, constant: 10).isActive = true
        scrollBtn.topAnchor.constraint(equalTo: v.topAnchor, constant: 6).isActive = true
        
        let singleLineBtn = NSButton(title: "SingleLine", target: self, action: #selector(onSingleLineBtnTapped(sender:)))
        singleLineBtn.setButtonType(.pushOnPushOff)
        v.addSubview(singleLineBtn)
        singleLineBtn.translatesAutoresizingMaskIntoConstraints = false
        
        singleLineBtn.leadingAnchor.constraint(equalTo: scrollBtn.trailingAnchor, constant: 10).isActive = true
        singleLineBtn.topAnchor.constraint(equalTo: v.topAnchor, constant: 6).isActive = true
        
        return v
    }()
    
    lazy var filterLogLevelItems: NSView = {
        let v = NSView()
        let allBtn = LogLevelView(frame: .zero)
        let errorsBtn = LogLevelView(frame: .zero)
        let warningsBtn = LogLevelView(frame: .zero)
        v.addSubview(allBtn)
        v.addSubview(errorsBtn)
        v.addSubview(warningsBtn)
        
        func selectLogLevel(sender: LogLevelView) {
            allBtn.deSelect()
            errorsBtn.deSelect()
            warningsBtn.deSelect()
            sender.select()
            
            if (sender.string == "Errors") {
                selectedLogLevel = .error
            } else if (sender.string == "Warnings") {
                selectedLogLevel = .warn
            } else {
                selectedLogLevel = nil
            }
            reloadTableView()
        }

        v.translatesAutoresizingMaskIntoConstraints = false
        v.wantsLayer = true
        
        allBtn.string = "All"
        allBtn.clickHandler = selectLogLevel
        allBtn.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 0).isActive = true
        allBtn.widthAnchor.constraint(equalToConstant: 36).isActive = true
        allBtn.topAnchor.constraint(equalTo: v.topAnchor, constant: 0).isActive = true
        allBtn.heightAnchor.constraint(equalToConstant: 30).isActive = true
        allBtn.select()
        

        errorsBtn.string = "Errors"
        errorsBtn.clickHandler = selectLogLevel
        errorsBtn.leadingAnchor.constraint(equalTo: allBtn.trailingAnchor, constant: 10).isActive = true
        errorsBtn.widthAnchor.constraint(equalToConstant: 50).isActive = true
        errorsBtn.topAnchor.constraint(equalTo: v.topAnchor, constant: 0).isActive = true
        errorsBtn.heightAnchor.constraint(equalToConstant: 30).isActive = true
     
        warningsBtn.string = "Warnings"
        warningsBtn.clickHandler = selectLogLevel
        warningsBtn.leadingAnchor.constraint(equalTo: errorsBtn.trailingAnchor, constant: 10).isActive = true
        warningsBtn.widthAnchor.constraint(equalToConstant: 70).isActive = true
        warningsBtn.topAnchor.constraint(equalTo: v.topAnchor, constant: 0).isActive = true
        warningsBtn.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        return v
    }()
    
    private func handleLogs() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.handleLogs()
        }
        
        if self.tobeProcessedLogs.count <= 0 {
            return
        }
        
        let logs = self.tobeProcessedLogs
 
        let rowIndexSet = IndexSet(integersIn: (filteredMessages.count)...(filteredMessages.count - 1 + logs.count))

        filteredMessages.append(contentsOf: logs)
        tableView.insertRows(at: rowIndexSet)
        tableView.reloadData(forRowIndexes: rowIndexSet, columnIndexes: IndexSet(integersIn: 0...2))
        if shouldAutoScroll {
            tableView.scrollRowToVisible(filteredMessages.count - 1)
        }
        
        // 只要和 add 的在一个线程就可以了
        self.tobeProcessedLogs.removeAll()
    }

    var delegate: DetailViewControllerDelegate?
    
    func generateVerticalSeparator() -> NSView {
        let v = NSView()
        v.wantsLayer = true
        // v.layer?.backgroundColor = NSColor.red.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        
        let separator = NSView(frame: NSMakeRect(10, 0, 0.5, 26))
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor(calibratedRed: 190/255.0, green: 190/255.0, blue: 190/255.0, alpha: 1).cgColor
        v.addSubview(separator)
   
        return v
    }
    
    func addColumns() {
        let columnConfigure: [Dictionary<String, Any>] = [
            ["title": "Type", "identifier": "level", "width": 40.0, "minWidth": 40.0, "maxWidth": 50.0],
            ["title": "Date", "identifier": "date", "width": 100.0, "minWidth": 80.0, "maxWidth": 120.0],
            ["title": "Message", "identifier": "message", "width": 400.0, "minWidth": 200.0, "maxWidth": 2000.0],
        ]
        
        columnConfigure.forEach { dictionary in
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue:dictionary["identifier"] as! String))
            column.headerCell.title = dictionary["title"] as! String
            column.headerCell.stringValue = dictionary["title"] as! String
            column.width = CGFloat(dictionary["width"] as! Double)
            column.minWidth = CGFloat(dictionary["minWidth"] as! Double)
            column.maxWidth = CGFloat(dictionary["maxWidth"] as! Double)
            
            tableView.addTableColumn(column)
            
            if (dictionary["identifier"] as! String == "message") {
                messageColumn = column
            }
        }
        
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
    }

    init(windowController: MainWindowController) {
        self.windowController = windowController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0,
                                         y: 0,
                                         width: MainWindowController.defaultRect.width - 150,
                                         height: MainWindowController.defaultRect.height))

        filterTextField.delegate = self
        operationBar.addSubview(filterTextField)
        operationBar.addSubview(filterLogLevelItems)
        operationBar.addSubview(separator)
        view.addSubview(operationBar)
        view.addSubview(scrollView)
        
        scrollView.frame = view.bounds
        tableView.frame = view.bounds
        addColumns()
        
        operationBar.addSubview(etcItems)
        
        let textFieldAndLogItemBarSeparator = generateVerticalSeparator()
        operationBar.addSubview(textFieldAndLogItemBarSeparator)
        textFieldAndLogItemBarSeparator.trailingAnchor.constraint(equalTo: filterLogLevelItems.leadingAnchor).isActive = true
        textFieldAndLogItemBarSeparator.topAnchor.constraint(equalTo: operationBar.topAnchor, constant: 8).isActive = true
        textFieldAndLogItemBarSeparator.widthAnchor.constraint(equalToConstant: 20).isActive = true
        textFieldAndLogItemBarSeparator.bottomAnchor.constraint(equalTo: operationBar.bottomAnchor, constant: -8).isActive = true
        
        let logItemBarAndEtcItemSeparator = generateVerticalSeparator()
        operationBar.addSubview(logItemBarAndEtcItemSeparator)
        logItemBarAndEtcItemSeparator.trailingAnchor.constraint(equalTo: etcItems.leadingAnchor).isActive = true
        logItemBarAndEtcItemSeparator.topAnchor.constraint(equalTo: operationBar.topAnchor, constant: 8).isActive = true
        logItemBarAndEtcItemSeparator.widthAnchor.constraint(equalToConstant: 20).isActive = true
        logItemBarAndEtcItemSeparator.bottomAnchor.constraint(equalTo: operationBar.bottomAnchor, constant: -8).isActive = true
        
        etcItems.widthAnchor.constraint(equalToConstant: 290).isActive = true
        etcItems.trailingAnchor.constraint(equalTo: operationBar.trailingAnchor, constant: 10).isActive = true
        etcItems.topAnchor.constraint(equalTo: operationBar.topAnchor, constant: 3).isActive = true
        etcItems.bottomAnchor.constraint(equalTo: operationBar.bottomAnchor, constant: -3).isActive = true

        operationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        operationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        operationBar.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        operationBar.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: operationBar.topAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        filterTextField.leadingAnchor.constraint(equalTo: operationBar.leadingAnchor, constant: 6).isActive = true
        filterTextField.topAnchor.constraint(equalTo: operationBar.topAnchor, constant: 8).isActive = true
        filterTextField.trailingAnchor.constraint(equalTo: textFieldAndLogItemBarSeparator.leadingAnchor).isActive = true
        filterTextField.bottomAnchor.constraint(equalTo: operationBar.bottomAnchor, constant: -8).isActive = true
        
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.widthAnchor.constraint(equalTo: operationBar.widthAnchor).isActive = true
        separator.leadingAnchor.constraint(equalTo: operationBar.leadingAnchor).isActive = true
        separator.topAnchor.constraint(equalTo: operationBar.topAnchor).isActive = true
        
        filterLogLevelItems.widthAnchor.constraint(equalToConstant: 177).isActive = true
        filterLogLevelItems.trailingAnchor.constraint(equalTo: logItemBarAndEtcItemSeparator.leadingAnchor).isActive = true
        filterLogLevelItems.topAnchor.constraint(equalTo: filterTextField.topAnchor).isActive = true
        filterLogLevelItems.bottomAnchor.constraint(equalTo: filterTextField.bottomAnchor).isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor

        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
        
        handleLogs()
    }
    
    private func reloadTableView() {
        filteredMessages.removeAll()
        allMessages.forEach { log in
            if let selectedLogLevel = selectedLogLevel {
                if log.level != selectedLogLevel {
                    return
                }
            }
            
            if (filterText != "" && !log.message.localizedStandardContains(filterText)) {
                return
            }
            
            filteredMessages.append(log)
        }
        
        tableView.reloadData()
    }
    
}

extension DetailViewController {
    @objc func onScrollPauseBtnTapped(sender: NSButton) {
        shouldAutoScroll = !shouldAutoScroll
    }
    
    @objc func onClearBtnTapped(sender: NSButton) {
        clear()
    }
    
    @objc func onSingleLineBtnTapped(sender: NSButton) {
        singleLineOfMessage = !singleLineOfMessage
        tableView.reloadData()
    }
}

extension DetailViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(insertNewline(_:))) {
            filterText = textView.string
            reloadTableView()
            return true
        }
        return false
    }
}

extension DetailViewController: NSTableViewDataSource, NSTableViewDelegate {
    private struct Constants {
        static let rowIdentifier = "row"
    }

    private func valueForIdentifier(_ identifier: String, row: Int) -> String {
        if (identifier == "level") {
            return (filteredMessages[row].level).rawValue
        }
        if (identifier == "date") {
            return filteredMessages[row].date
        }
        if (identifier == "message") {
            return filteredMessages[row].message
        }
        print("value for identifier: \(identifier) is empty")
        return ""
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredMessages.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if (!singleLineOfMessage) {
            let cell = self.tableView(tableView, viewFor: messageColumn, row: row) as! DetailTableViewColumnCell
            cell.aTextField.preferredMaxLayoutWidth = messageColumn!.width
            cell.layoutSubtreeIfNeeded()
            let height = cell.aTextField.sizeThatFits(NSMakeSize(messageColumn!.width, CGFloat.greatestFiniteMagnitude)).height
            return height + 8
        }
        return 24
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let identifier = (tableColumn?.identifier.rawValue)!
        return valueForIdentifier(identifier, row: row)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as? DetailTableViewColumnCell
        if cell == nil {
            cell = DetailTableViewColumnCell()
        }
        
        let identifier = (tableColumn?.identifier.rawValue)!
        let text = valueForIdentifier(identifier, row: row)
        
        if (!singleLineOfMessage) {
            cell?.aTextField.cell?.usesSingleLineMode = false
            cell?.aTextField.cell?.isScrollable = false
            cell?.aTextField.cell?.lineBreakMode = .byWordWrapping
        } else {
            cell?.aTextField.cell?.usesSingleLineMode = true
            cell?.aTextField.cell?.isScrollable = true
            cell?.aTextField.cell?.lineBreakMode = .byClipping
        }

        cell?.configure(text: text, level: filteredMessages[row].level)
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        // let selected = tableView.selectedRow
    }
}

extension DetailViewController: NSTextViewDelegate {
    func textView(_ textView: NSTextView, clickedOn cell: NSTextAttachmentCellProtocol, in cellFrame: NSRect, at charIndex: Int) {
        print("clicked")
    }
}

extension DetailViewController {
    func add(log: LogItem) {
        allMessages.append(log)
        
        if let selectedLogLevel = selectedLogLevel {
            if log.level != selectedLogLevel {
                return
            }
        }
        
        if (filterText != "" && !log.message.localizedStandardContains(filterText)) {
            return
        }
        
        tobeProcessedLogs.append(log)
    }

    func add(messages: Array<LogItem>) {
        DispatchQueue.main.async {
            self.tobeProcessedLogs.removeAll()
            self.allMessages.removeAll()
            self.filteredMessages.removeAll()
            
            messages.forEach { log in
                self.add(log: log)
            }
            self.tableView.reloadData()
            self.tableView.scrollRowToVisible(self.tobeProcessedLogs.count-1)
        }
    }
    
    func clear() {
        tobeProcessedLogs.removeAll()
        allMessages.removeAll()
        filteredMessages.removeAll()
        tableView.reloadData()
        
        if let delegate = self.delegate {
            delegate.didClear()
        }
    }
    
    func reload() {
        tableView.reloadData()
    }
}

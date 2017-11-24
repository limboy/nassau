//
//  MainWindowController.swift
//  Nassau
//
//  Created by limboy on 09/11/2017.
//  Copyright © 2017 limboy. All rights reserved.
//

import Cocoa

struct LogItem {
    var tag: String
    var level: LogLevel
    var date: String
    var timestamp: Double
    var message: String
}

class MainWindowController: NSWindowController {

    // MARK: privates
    private var wc:SettingWindowController?
    
    static var defaultRect: NSRect {
        return NSMakeRect(0, 0, 900, 600)
    }
    
    private var logObserver: LogDataObserverProtocol?
    
    private var latestPid: String?
    
    private var latestADBKeyword: String = ""
    
    private var task: Foundation.Process = Foundation.Process()
    
    private var usbWatcher: USBWatcher?
    
    private var shouldCheckADB = true
    
    private var isHandlingWindowResizing = false

    private var usbDevices = Set<String>()
    
    lazy var waitingForADBViewController: WaitingForADBViewController = {
        var v = WaitingForADBViewController(windowController: self)
        
        return v
    }()
    
    lazy var loggerViewController:LoggerViewController = {
        var v = LoggerViewController(windowController: self)
        
        return v
    }()
    
    private var latestPackageName = ""
    
    // MARK: target-action
    @IBAction func onPreferenceClicked(_ sender: NSMenuItem) {
        wc = SettingWindowController()
        wc?.showWindow(nil)
        wc?.windowDidLoad()
    }

    // MARK: Life Cycles
    init() {
        let window = NSWindow()
        window.title = "Nassau"
        super.init(window: window)
        window.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        checkADB()
        // contentViewController = loggerViewController
        showWindow(self)
        usbWatcher = USBWatcher(delegate: self)

        window?.titleVisibility = .visible
        window?.styleMask = [.closable, .miniaturizable, .titled, .resizable]
        let x = (window?.screen?.frame.size.width)! / 2 - (MainWindowController.defaultRect.size.width) / 2
        let y = (window?.screen?.frame.size.height)! / 2 - (MainWindowController.defaultRect.size.height) / 2
        resizeWindowFrame(position: CGPoint(x: x, y: y))
    }
    
    private func parseAndroidRequest(data: Dictionary<String, Any>) {
        if let action = data["action"] as? String {
            if action == "availableCommands" {
                if let content = data["content"] as? [[String:String]] {
                    loggerViewController.commands = content
                }
            }
        }
    }

    // MARK: private methods
    private func checkADB() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
            self.checkADB()
        }
        
        func showWaiting() {
            if contentViewController != waitingForADBViewController {
                self.window?.title = "Nassau"
                loggerViewController.clear()
                let currentWindowSize = self.window!.frame.size
                let currentOrigin = self.window!.frame.origin
                contentViewController = waitingForADBViewController
                resizeWindowFrame(position: currentOrigin, size: currentWindowSize)
            }
        }
        
        if !shouldCheckADB {
            showWaiting()
            return
        }
        
        let adbKeyword = (NSApplication.shared.delegate as! AppDelegate).adbKeyword
        
        if (adbKeyword != "") {
            if adbKeyword == latestADBKeyword || contentViewController != loggerViewController {
                return
            }
            
            requestDeviceCommandOptions()
            
            latestPackageName = ""
            latestPid = ""
            
            self.window?.title = "Nassau (\(adbKeyword))"
            latestADBKeyword = adbKeyword
            
            if (contentViewController != loggerViewController) {
                contentViewController = loggerViewController
            }
            
            loggerViewController.clear()
            streamLog(pid: "", adbKeyword: adbKeyword)

            let currentWindowSize = self.window!.frame.size
            let currentOrigin = self.window!.frame.origin
            resizeWindowFrame(position: currentOrigin, size: currentWindowSize)
        } else {
            let packageName = extractCurrentPackageName()
            
            if packageName == "" {
                showWaiting()
            } else {
                if latestPackageName != packageName || contentViewController != loggerViewController {
                    
                    requestDeviceCommandOptions()
                    
                    latestPackageName = packageName
                    
                    self.window?.title = "Nassau (\(packageName))"
                    
                    if (contentViewController != loggerViewController) {
                        contentViewController = loggerViewController
                    }
                    
                    loggerViewController.clear()
                    
                    let pid = getCurrentAppPid(packageName: packageName)
                    if let pid = pid {
                        if (pid != latestPid) {
                            streamLog(pid: pid, adbKeyword: adbKeyword)
                        }
                    } else {
                        NSLog("pid not found")
                    }
                    
                    latestPid = pid
                    let currentWindowSize = self.window!.frame.size
                    let currentOrigin = self.window!.frame.origin
                    resizeWindowFrame(position: currentOrigin, size: currentWindowSize)
                }
            }
        }
    }
    
    private func resizeWindowFrame(position:NSPoint? = nil, size: CGSize? = nil) {
        var width = MainWindowController.defaultRect.size.width
        var height = MainWindowController.defaultRect.size.height
        var x = window!.frame.origin.x
        var y = window!.frame.origin.y
        
        if let size = size {
            width = size.width
            height = size.height
        }
        
        if let position = position {
            x = position.x
            y = position.y
        }
        
        let frame = NSMakeRect(x, y, width, height)
        window?.setFrame(frame, display: false)
    }
    
    // for Android
    private func extractCurrentPackageName() -> String {
        let adbPath = (NSApplication.shared.delegate as! AppDelegate).adbPath
        var result:String?
        do {
            result = try Shell().outputOf(commandName: adbPath, arguments: ["shell", "dumpsys", "activity", "activities", "|", "grep", "TaskRecord"])
        } catch let error {
            print("error while executing extrat package name: \(error)")
            return ""
        }

        guard let str = result else {
            return ""
        }
        
        if str.contains(" not found") {
            waitingForADBViewController.showChangeADBPath()
        } else {
            waitingForADBViewController.hideChangeADBPath()
        }

        // 国产的 Android 机上，有时会出现第一种情况
        let regexes = [".*0\\: TaskRecord.*A=([^ ^}]*)", ".*\\* TaskRecord.*A[= ]([^ ^}]*)"]
        var packageName = ""

        for (idx, regex) in regexes.enumerated() {
            do {
                let result = try NSRegularExpression(pattern: regex, options: NSRegularExpression.Options.caseInsensitive)
                
                let option = (idx == 0) ? NSRegularExpression.MatchingOptions.reportCompletion : NSRegularExpression.MatchingOptions.anchored
                
                let results = result.matches(in: str, options: option, range: NSRange(str.startIndex..., in: str))
                
                for (_, item) in results.enumerated() {
                    let matched = String(str[Range(item.range, in: str)!])
                    let segments = matched.split(separator: "=")
                    packageName = segments[1].description
                    if packageName != "" {
                        break
                    }
                }
            } catch let error {
                print(error)
                NSLog("error: %@", error.localizedDescription)
            }
            
            if packageName != "" {
                break
            }
        }
        
        return packageName.components(separatedBy: " ")[0]
    }
    
    private func getCurrentAppPid(packageName: String) -> String? {
        let adbPath = (NSApplication.shared.delegate as! AppDelegate).adbPath

        var result: String?
        do {
            result = try Shell().outputOf(commandName: adbPath, arguments: ["shell", "ps", "|", "grep", packageName])
        } catch let error {
            print("error while get current app pid: \(error)")
            return nil
        }
        
        guard let str = result else {
            return nil
        }
        
        let results = str.components(separatedBy: "\n")
        
        for (_, item) in results.enumerated() {
            var segments = item.components(separatedBy: " ")
            segments = segments.filter {return $0 != ""}
            
            if (segments.count > 0) {
                // 有些机器上会有这些字符
                let lastSegment = segments.last!
                        .replacingOccurrences(of: "\r", with: "")
                        .replacingOccurrences(of: "\n", with: "")
                
                if (packageName == lastSegment) {
                    var filteredSegments:[String] = segments.filter {$0 != ""}
                    return filteredSegments[1]
                }
            }
        }
        return nil
    }
    
    private func parseLogLine(line: String, rule: (String, String) -> Bool) -> LogItem? {
        if line != "" {
            if (line.first == ".") {
                return nil
            }
        }
        
        let endBraceIndex = line.index(of: ")")
        
        guard let endBrace = endBraceIndex else {
            return nil
        }
        
        let startBraceIdx = line.index(of: "(")
        
        guard let startBrace = startBraceIdx else {
            return nil
        }
        
        var startBraceIndex = line.index(startBrace, offsetBy: 1)
        
        if (endBrace.encodedOffset < startBraceIndex.encodedOffset) {
            print("error line: \(line)")
            return nil
        }
        
        let parsedPid = String(line[startBraceIndex..<endBrace]).trimmingCharacters(in: [" "])
        
        let shouldContinue = rule(line, parsedPid)
        
        if (shouldContinue) {
            let segments = line.components(separatedBy: " ")
            let time = segments[0] + " " + segments[1]
            
            let metaInfo = segments[2]
            let logLevelStr = metaInfo[metaInfo.index(metaInfo.startIndex, offsetBy: 0)]
            var logLevel:LogLevel = .debug
            
            switch logLevelStr {
            case "I":
                logLevel = .info
            case "D":
                logLevel = .debug
            case "V":
                logLevel = .verbose
            case "W":
                logLevel = .warn
            case "E":
                logLevel = .error
            default:
                logLevel = .debug
            }
            
            startBraceIndex = line.index(line.index(of: "/")!, offsetBy: 1)
            let endBraceIndex = line.index(of: "(")!
            let tagName = String(line[startBraceIndex..<endBraceIndex])
            
            let colonIndex = line.index(line.index(of: ")")!, offsetBy: 3)
            let message = line[colonIndex...]
            
            let timestamp = Date().timeIntervalSince1970
            
            return LogItem(tag: tagName, level: logLevel, date: time, timestamp: timestamp, message: String(message))
        }
        return nil
    }
    
    private func streamLog(pid: String, adbKeyword: String) {
        let adbPath = (NSApplication.shared.delegate as! AppDelegate).adbPath
        let adbKeyword = (NSApplication.shared.delegate as! AppDelegate).adbKeyword

        func _parseLogLine(line: String) -> LogItem? {
            return self.parseLogLine(line: line, rule: { (_line, _pid) -> Bool in
                if adbKeyword == "" {
                    return _pid == pid
                } else {
                    return _line.lowercased().contains(adbKeyword.lowercased())
                }
            })
        }
        
        if task.isRunning {
            let p = task.standardOutput as! Pipe
            p.fileHandleForReading.closeFile()
            task.terminate()
        }

        task = Process()
        
        task.launchPath = "/bin/sh"
        let extraArguments = adbKeyword == "" ? " | grep \(pid)" : ""
        task.arguments = ["-c", "\(adbPath) logcat -v time \(extraArguments)"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        let outHandle = pipe.fileHandleForReading
        
        var lastItem = ""
        outHandle.readabilityHandler = { pipe in
            let data = pipe.readData(ofLength: 512)
            
            if data.count <= 0 {
                pipe.closeFile()
                return
            }
            
            if let line = String(data: data, encoding: String.Encoding.utf8) {
                let lines = line.components(separatedBy: .newlines)
                for (index, item) in lines.enumerated() {
                    if (index == 0) {
                        let result = _parseLogLine(line: lastItem + item)
                        if let result = result {
                            self.logObserver?.add(log: result)
                        }
                    } else if (index < lines.count - 1) {
                        let result = _parseLogLine(line: item)

                        if let result = result {
                            self.logObserver?.add(log: result)
                        }
                    } else {
                        lastItem = item
                    }
                }
            } else {
                NSLog("error decoding data: %@", pipe.availableData.description)
            }
        }
        
        task.launch()
    }
}

// MARK: public methods
extension MainWindowController {
    func startup() -> Void {
        windowDidLoad()
    }

    func addLogObserver(_ observer: LogDataObserverProtocol) {
        logObserver = observer
    }
}

extension MainWindowController {
    func requestDeviceCommandOptions() {
        let adbPath = (NSApplication.shared.delegate as! AppDelegate).adbPath
        DispatchQueue.global().async {
            let _ = try! Shell().outputOf(commandName: adbPath, arguments: ["reverse", "tcp:23333", "tcp:8037"])
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                let _ = try! Shell().outputOf(commandName: adbPath, arguments: ["shell", "am", "broadcast", "-a", "nassau.REQUEST", "--es", "getAvailableCommands", "hello"])
            })
        }
    }
}

extension MainWindowController: USBWatcherDelegate {
    
    private func checkIfMaybeAnAndroid(deviceName: String) -> Bool {
        let keywords = [" USB", " Hub", "Apple", "iPhone"]
        for (_, keyword) in keywords.enumerated() {
            if deviceName.contains(keyword) {
                return false
            }
        }
        return true
    }
    
    private func checkIfShouldStartADB() {
        // 看看剩下的还有没有 Android 设备
        var maybeTheresAnAndroidDevice = false
        for (_, device) in usbDevices.enumerated() {
            if checkIfMaybeAnAndroid(deviceName: device) {
                maybeTheresAnAndroidDevice = true
            }
        }
        self.shouldCheckADB = maybeTheresAnAndroidDevice
        if !self.shouldCheckADB {
            latestPackageName = ""
            latestPid = nil
            
            if task.isRunning {
                let p = task.standardOutput as! Pipe
                p.fileHandleForReading.closeFile()
                task.terminate()
            }
            
        }
    }
    
    func deviceAdded(_ device: io_object_t) {
        print("device added: \(device.name() ?? "<unknown>")")
        if let deviceName = device.name() {
            usbDevices.insert(deviceName)
            checkIfShouldStartADB()
        }
    }
    
    func deviceRemoved(_ device: io_object_t) {
        print("device removed: \(device.name() ?? "<unknown>")")
        if let deviceName = device.name() {
            usbDevices.remove(deviceName)
            checkIfShouldStartADB()
        }
    }
}

extension MainWindowController: NSWindowDelegate {
    func windowDidResize(_ notification: Notification) {
        // 因为一次 resize window 往往会导致多个回调
        guard !isHandlingWindowResizing else {
            return
        }
        
        isHandlingWindowResizing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000), execute: {
            self.isHandlingWindowResizing = false
            if self.contentViewController == self.loggerViewController {
                self.loggerViewController.onWindowResize()
            }
        })
        
    }
}

//
// Created by limboy on 09/11/2017.
// Copyright (c) 2017 limboy. All rights reserved.
//

import Foundation

enum LogLevel: String {
    case verbose, debug, info, warn, error, fatal
}

protocol LogDataObserverProtocol {
    func add(log: LogItem)
}
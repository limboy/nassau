//
// Created by limboy on 18/11/2017.
// Copyright (c) 2017 limboy. All rights reserved.
//

import Foundation

final class Shell
{
    func outputOf(commandName: String, arguments: [String] = []) throws -> String? {
        return bash(commandName: commandName, arguments:arguments)
    }

    // MARK: private
    private func bash(commandName: String, arguments: [String]) -> String? {
        guard var whichPathForCommand = executeShell(command: "/bin/bash" , arguments:["-c", "which \(commandName)" ]) else {
            return "\(commandName) not found"
        }
        whichPathForCommand = whichPathForCommand.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        return executeShell(command: whichPathForCommand, arguments: arguments)
    }

    private func executeShell(command: String, arguments: [String] = []) -> String? {
        let task = Process()
        task.launchPath = command
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String? = String(data: data, encoding: String.Encoding.utf8)

        return (output == "" || output == nil) ? nil : output
    }
}

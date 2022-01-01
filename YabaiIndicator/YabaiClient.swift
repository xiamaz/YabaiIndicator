//
//  YabaiClient.swift
//  YabaiIndicator
//
//  Created by Max Zhao on 01/01/2022.
//

import SwiftUI

@discardableResult
func yabai(_ args: String...) -> Int32 {
    let task = Process()
    let yabaiPath = UserDefaults.standard.string(forKey: "yabaiPath")
    task.launchPath = yabaiPath
    task.arguments = args
    do {
        try task.run()
    } catch {
        print(error)
        return 1
    }
    task.waitUntilExit()
    let status = task.terminationStatus
    return status
}

func focusSpace(index: Int) {
    yabai(
        "-m", "space", "--focus", "\(index)")
}

func checkYabai() -> Bool {
    let valid = yabai("-v") == 0
    return valid
}

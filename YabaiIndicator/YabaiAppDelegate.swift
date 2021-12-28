//
//  YabaiAppDelegate.swift
//  YabaiIndicator
//
//  Created by Max Zhao on 26/12/2021.
//

import SwiftUI

class YabaiAppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var application: NSApplication = NSApplication.shared
     var spaces = Spaces()

    @objc
    func onSpaceChanged(_ notification: Notification) {
       refreshData()
    }
    
    @objc
    func onDisplayChanged(_ notification: Notification) {
       refreshData()
    }
    
    func refreshData() {
        let g_connection = SLSMainConnectionID()
        
        let activeDisplayUUID = SLSCopyActiveMenuBarDisplayIdentifier(g_connection).takeRetainedValue() as String
    
        let displaySpaces = SLSCopyManagedDisplaySpaces(g_connection).takeRetainedValue() as [AnyObject]
        
        var totalSpaces = 0
        var visibleSpaces:[Int] = []
        for displaySpace in displaySpaces {
            let spaces = displaySpace["Spaces"] as? [NSDictionary] ?? []
            let current = displaySpace["Current Space"] as? NSDictionary
            // let currentUUID = current["uuid"] as? String
            let currentUUID = current?["uuid"] as? String ?? ""
            let activeDisplay = activeDisplayUUID == displaySpace["Display Identifier"] as? String ?? ""
            
            for space:NSDictionary in spaces {
                totalSpaces += 1
                if space["uuid"] as? String == currentUUID {
                    if activeDisplay {
                        self.spaces.activeSpace = totalSpaces
                    }
                    visibleSpaces.append(totalSpaces)
                }
            }
        }
        
        spaces.allSpaces = Array(1...totalSpaces)
        spaces.visibleSpaces = visibleSpaces
        
        let newWidth = CGFloat(totalSpaces) * 30.0
        statusBarItem?.button?.frame.size.width = newWidth
        statusBarItem?.button?.subviews[0].frame.size.width = newWidth
        
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let menuItem = NSMenuItem()

        // SwiftUI View
        let view = NSHostingView(
            rootView: ContentView().environmentObject(spaces)
        )
        
        let barWidth = 22 * 6.0

        // Very important! If you don't set the frame the menu won't appear to open.
        view.frame = NSRect(x: 0, y: 0, width: barWidth, height: 22)
        menu.addItem(menuItem)

        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem?.menu = menu
        statusBarItem?.button?.addSubview(view)
        statusBarItem?.button?.isEnabled = false
        statusBarItem?.button?.frame.size.width = barWidth
        
        refreshData()
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.onSpaceChanged(_:)), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.onDisplayChanged(_:)), name: Notification.Name("NSWorkspaceActiveDisplayDidChangeNotification"), object: nil)
    }
}

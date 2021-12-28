//
//  YabaiAppDelegate.swift
//  YabaiIndicator
//
//  Created by Max Zhao on 26/12/2021.
//

import SwiftUI
import Socket

class YabaiAppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var application: NSApplication = NSApplication.shared
    var spaces = Spaces(spaces: [])
    
    let g_connection = SLSMainConnectionID()

    @objc
    func onSpaceChanged(_ notification: Notification) {
        refreshData()
    }
    
    @objc
    func onDisplayChanged(_ notification: Notification) {
        refreshData()
    }
    
    func refreshData() {
        // NSLog("Refreshing")        
        let activeDisplayUUID = SLSCopyActiveMenuBarDisplayIdentifier(g_connection).takeRetainedValue() as String
    
        let displays = SLSCopyManagedDisplaySpaces(g_connection).takeRetainedValue() as [AnyObject]
        
        var spaceIncr = 0
        var totalSpaces = 0
        var spaces:[Space] = []
        for display in displays {
            let displaySpaces = display["Spaces"] as? [NSDictionary] ?? []
            let current = display["Current Space"] as? NSDictionary
            // let currentUUID = current["uuid"] as? String
            let currentUUID = current?["uuid"] as? String ?? ""
            let displayUUID = display["Display Identifier"] as? String ?? ""
            let activeDisplay = activeDisplayUUID == displayUUID
            
            if (totalSpaces > 0) {
                spaces.append(Space(id: 0, uuid: "", visible: false, active: false, displayUUID: "", index: 0, yabaiIndex: totalSpaces, type: -1))
            }
            
            for nsSpace:NSDictionary in displaySpaces {
                let spaceId = nsSpace["id64"] as? UInt64 ?? 0
                let spaceUUID = nsSpace["uuid"] as? String ?? ""
                let visible = spaceUUID == currentUUID
                let active = visible && activeDisplay
                let spaceType = nsSpace["type"] as? Int ?? 0
                
                var spaceIndex = 0
                totalSpaces += 1
                if spaceType == 0 {
                    spaceIncr += 1
                    spaceIndex = spaceIncr
                }
                
                spaces.append(Space(id: spaceId, uuid: spaceUUID, visible: visible, active: active, displayUUID: displayUUID, index: spaceIndex, yabaiIndex: totalSpaces, type: spaceType))
            }
        }
        self.spaces.spaceElems = spaces
                
        let newWidth = CGFloat(totalSpaces) * 30.0
        //statusBarItem?.button?.frame.size.width = newWidth
        //statusBarItem?.button?.subviews[0].frame.size.width = newWidth
        statusBarItem?.view?.frame.size.width = newWidth
        
    }
    
    func socketServer() async {

        do {
            let socket = try Socket.create(family: .unix, type: .stream, proto: .unix)
            try socket.listen(on: "/tmp/yabai-indicator.socket")
            while true {
                let conn = try socket.acceptClientConnection()
                let msg = try conn.readString()?.trimmingCharacters(in: .whitespacesAndNewlines)
                conn.close()
                // NSLog("Received message: \(msg!).")
                if msg == "refresh" {
                    DispatchQueue.main.async {
                        // NSLog("Refreshing on main thread")
                        self.refreshData()
                    }
                }
            }
        } catch {
            NSLog("SocketServer Error: \(error)")
        }
        NSLog("SocketServer Ended")
    }
    
    @objc
    func quit() {
        NSApp.terminate(self)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task {
            await self.socketServer()
        }
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // SwiftUI View
        let view = NSHostingView(
            rootView: ContentView().environmentObject(spaces)
        )
        
        view.setFrameSize(NSSize(width: 0, height: 18))
        
        statusBarItem?.view = view
        // statusBarItem?.button?.addSubview(view)
        // statusBarItem?.button?.isEnabled = true
        
        let statusBarMenu = NSMenu(title: "Yabai Indicator Menu")
        statusBarItem?.menu = statusBarMenu
        statusBarMenu.addItem(
            withTitle: "Quit",
            action: #selector(quit),
            keyEquivalent: "")
        
        refreshData()
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.onSpaceChanged(_:)), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.onDisplayChanged(_:)), name: Notification.Name("NSWorkspaceActiveDisplayDidChangeNotification"), object: nil)
    }
}

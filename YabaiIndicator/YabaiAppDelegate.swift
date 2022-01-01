//
//  YabaiAppDelegate.swift
//  YabaiIndicator
//
//  Created by Max Zhao on 26/12/2021.
//

import SwiftUI
import Socket
import Combine

extension UserDefaults {
    @objc dynamic var showDisplaySeparator: Bool {
        return bool(forKey: "showDisplaySeparator")
    }
    
    @objc dynamic var showCurrentSpaceOnly: Bool {
        return bool(forKey: "showCurrentSpaceOnly")
    }
}

class YabaiAppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var application: NSApplication = NSApplication.shared
    var spaces = Spaces(spaces: [])
    
    let g_connection = SLSMainConnectionID()
    let statusBarHeight = 22
    let itemWidth:CGFloat = 30
    
    var refreshSink: AnyCancellable?
    var separatorSink: AnyCancellable?
    var displaySink: AnyCancellable?


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
                spaces.append(Space(id: 0, uuid: "", visible: true, active: false, displayUUID: "", index: 0, yabaiIndex: totalSpaces, type: -1))
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
        self.spaces.totalSpaces = totalSpaces
        self.spaces.totalDisplays = displays.count
    }
    
    func refreshBar() {
        let showDisplaySeparator = UserDefaults.standard.bool(forKey: "showDisplaySeparator")
        let showCurrentSpaceOnly = UserDefaults.standard.bool(forKey: "showCurrentSpaceOnly")
        
        let numButtons = showCurrentSpaceOnly ?  spaces.totalDisplays : spaces.totalSpaces
        
        var newWidth = CGFloat(numButtons) * itemWidth
        if !showDisplaySeparator {
            newWidth -= CGFloat((spaces.totalDisplays - 1) * 10)
        }
        statusBarItem?.button?.frame.size.width = newWidth
        statusBarItem?.button?.subviews[0].frame.size.width = newWidth

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
    
    @objc
    func openPreferences() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func createStatusItemView() -> NSView {
        let view = NSHostingView(
            rootView: ContentView().environmentObject(spaces)
        )
        view.setFrameSize(NSSize(width: 0, height: statusBarHeight))
        return view
    }
    
    func createMenu() -> NSMenu {
        let statusBarMenu = NSMenu()
        statusBarMenu.addItem(
            withTitle: "Preferences",
            action: #selector(openPreferences),
            keyEquivalent: "")
        statusBarMenu.addItem(NSMenuItem.separator())

        statusBarMenu.addItem(
            withTitle: "Quit",
            action: #selector(quit),
            keyEquivalent: "")
        return statusBarMenu
    }
    
    func registerObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.onSpaceChanged(_:)), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.onDisplayChanged(_:)), name: Notification.Name("NSWorkspaceActiveDisplayDidChangeNotification"), object: nil)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let prefs = Bundle.main.path(forResource: "defaults", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: prefs) as? [String : Any] {
          UserDefaults.standard.register(defaults: dict)
        }
        
        refreshSink = spaces.objectWillChange.sink{_ in self.refreshBar()}
        separatorSink = UserDefaults.standard.publisher(for: \.showDisplaySeparator).sink {_ in self.refreshBar()}
        displaySink = UserDefaults.standard.publisher(for: \.showCurrentSpaceOnly).sink {_ in self.refreshBar()}

        
        Task {
            await self.socketServer()
        }
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        statusBarItem?.button?.addSubview(createStatusItemView())
        statusBarItem?.menu = createMenu()
        
        refreshData()
        
        registerObservers()

    }
}

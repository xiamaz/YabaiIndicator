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
    
    @objc dynamic var buttonStyle: ButtonStyle {
        get {
            return ButtonStyle(rawValue: self.integer(forKey: "buttonStyle")) ?? ButtonStyle.numeric
        }
    }
}

class YabaiAppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var application: NSApplication = NSApplication.shared
    var spaces = SpaceModel()
    
    let statusBarHeight = 22
    let itemWidth:CGFloat = 30
    
    var sinks: [AnyCancellable?] = []
    var receiverQueue = DispatchQueue(label: "yabai-indicator.socket.receiver")

    @objc
    func onSpaceChanged(_ notification: Notification) {
        onSpaceRefresh()
    }
    
    @objc
    func onDisplayChanged(_ notification: Notification) {
        onSpaceRefresh()
    }
    
    func refreshData() {
        // NSLog("Refreshing")
        receiverQueue.async {
            self.onDisplayRefresh()
            self.onSpaceRefresh()
            self.onWindowRefresh()
        }
    }
    
    func onSpaceRefresh() {
        let spaceElems = gNativeClient.querySpaces()
        let totalDisplays = spaceElems.map{return $0.display}.max()
        
        DispatchQueue.main.async {
            self.spaces.spaces = spaceElems
            self.spaces.totalDisplays = totalDisplays ?? 0
        }
    }
    
    func onWindowRefresh() {
        if UserDefaults.standard.buttonStyle == .windows {
            let windows = gYabaiClient.queryWindows()
            DispatchQueue.main.async {
                self.spaces.windows = windows
            }
        }
    }
    
    func onDisplayRefresh() {
        if UserDefaults.standard.buttonStyle == .windows {
            let displays = gNativeClient.queryDisplays()
            DispatchQueue.main.async {
                self.spaces.displays = displays
                self.spaces.totalDisplays = displays.count
            }
        }
    }
    
    func refreshBar() {
        let showDisplaySeparator = UserDefaults.standard.bool(forKey: "showDisplaySeparator")
        let showCurrentSpaceOnly = UserDefaults.standard.bool(forKey: "showCurrentSpaceOnly")
        
        let numButtons = showCurrentSpaceOnly ?  spaces.totalDisplays : spaces.spaces.count
        
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
                    self.refreshData()
                    receiverQueue.async {
                        // NSLog("Refreshing on main thread")
                        // self.refreshData()
                    }
                } else if msg == "refresh spaces" {
                    receiverQueue.async {
                        // NSLog("Refreshing on main thread")
                        self.onSpaceRefresh()
                    }
                } else if msg == "refresh windows" {
                    receiverQueue.async {
                        // NSLog("Refreshing on main thread")
                        self.onWindowRefresh()
                    }
                } else if msg == "refresh displays" {
                    receiverQueue.async {
                        // NSLog("Refreshing on main thread")
                        self.onDisplayRefresh()
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
    
    func refreshButtonStyle() {
        for subView in statusBarItem?.button?.subviews ?? [] {
            subView.removeFromSuperview()
        }
        statusBarItem?.button?.addSubview(createStatusItemView())
        refreshData()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let prefs = Bundle.main.path(forResource: "defaults", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: prefs) as? [String : Any] {
          UserDefaults.standard.register(defaults: dict)
        }
        
        sinks = [
            spaces.objectWillChange.sink{_ in self.refreshBar()},
            UserDefaults.standard.publisher(for: \.showDisplaySeparator).sink {_ in self.refreshBar()},
            UserDefaults.standard.publisher(for: \.showCurrentSpaceOnly).sink {_ in self.refreshBar()},
            UserDefaults.standard.publisher(for: \.buttonStyle).sink {_ in self.refreshButtonStyle()}

        ]
        
        Task {
            await self.socketServer()
        }
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        statusBarItem?.menu = createMenu()
        
        refreshButtonStyle()
        registerObservers()
    }
}

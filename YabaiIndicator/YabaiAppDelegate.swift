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
    var menu: NSMenu?
    var statusBarItem: NSStatusItem?
    var application: NSApplication = NSApplication.shared
    var spaceModel = SpaceModel()
    
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
            self.onSpaceRefresh()
            self.onWindowRefresh()
        }
    }
    
    func onSpaceRefresh() {
        let displays = gNativeClient.queryDisplays()
        let spaceElems = gNativeClient.querySpaces()
        
        DispatchQueue.main.async {
            self.spaceModel.displays = displays
            self.spaceModel.spaces = spaceElems
        }
    }
    
    func onWindowRefresh() {
        if UserDefaults.standard.buttonStyle == .windows {
            let windows = gYabaiClient.queryWindows()
            DispatchQueue.main.async {
                self.spaceModel.windows = windows
            }
        }
    }
    
    func refreshBar() {
        let showDisplaySeparator = UserDefaults.standard.bool(forKey: "showDisplaySeparator")
        let showCurrentSpaceOnly = UserDefaults.standard.bool(forKey: "showCurrentSpaceOnly")
        
        let numButtons = showCurrentSpaceOnly ?  spaceModel.displays.count : spaceModel.spaces.count
        
        var newWidth = CGFloat(numButtons) * itemWidth
        if !showDisplaySeparator {
            newWidth -= CGFloat((spaceModel.displays.count - 1) * 10)
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
      if #available(macOS 13, *) {
          NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
      } else {
          NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
      }
      NSApp.activate(ignoringOtherApps: true)
    }
    
    func createStatusItemView() -> NSView {
        let view = NSHostingView(
            rootView: ContentView().environmentObject(spaceModel)
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
            spaceModel.objectWillChange.sink{_ in self.refreshBar()},
            UserDefaults.standard.publisher(for: \.showDisplaySeparator).sink {_ in self.refreshBar()},
            UserDefaults.standard.publisher(for: \.showCurrentSpaceOnly).sink {_ in self.refreshBar()},
            UserDefaults.standard.publisher(for: \.buttonStyle).sink {_ in self.refreshButtonStyle()}

        ]
        
        Task {
            await self.socketServer()
        }
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu = createMenu()
        statusBarItem?.button?.action = #selector(statusMenuButtonTouched)
        statusBarItem?.button?.sendAction(on: [.rightMouseUp])

        refreshButtonStyle()
        registerObservers()
    }

    @objc
    private func statusMenuButtonTouched() {
        menu?.popUp(positioning: nil, at: NSPoint.zero, in: statusBarItem?.button!)
    }
}

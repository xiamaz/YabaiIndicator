//
//  SettingsView.swift
//  YabaiIndicator
//
//  Created by Max Zhao on 1/1/22.
//

import SwiftUI

struct SettingsView : View {
    @AppStorage("showDisplaySeparator") private var showDisplaySeparator = true
    @AppStorage("showCurrentSpaceOnly") private var showCurrentSpaceOnly = false
    @AppStorage("yabaiPath") private var yabaiPath = ""
    
    @State private var validPath = false
    @State private var editedPath = false
    
    private enum Tabs: Hashable {
        case general, advanced
    }
    
    private func checkYabaiPath() {
        validPath = checkYabai()
        editedPath = true
    }
    
    var body: some View {
        TabView {
            Form {
                Toggle("Show Display Separator", isOn: $showDisplaySeparator)
                Toggle("Show Current Space Only", isOn: $showCurrentSpaceOnly)
                VStack{
                HStack {
                    Text("Yabai Path")
                    TextField("Yabai Path", text: $yabaiPath)
                    Button("Check", action: checkYabaiPath)
                }
                if (editedPath) {
                    Text(validPath ? "Valid yabai binary" : "Invalid path").foregroundColor(validPath ? Color.green : Color.red)
                }
                    Spacer()
                }
            }.padding(10)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            
        }
        .frame(width: 375, height: 120)
    }
}

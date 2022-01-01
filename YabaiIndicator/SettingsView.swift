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
    @AppStorage("yabaiPath") private var yabaiPath = "/usr/local/bin/yabai"
    
    var body: some View {
        Form {
            Toggle("Show Display Separator", isOn: $showDisplaySeparator)
            Toggle("Show Current Space Only", isOn: $showCurrentSpaceOnly)
            VStack {
                TextField("Yabai Path", text: $yabaiPath).textFieldStyle(.plain)
                Divider()
            }.padding(5).disabled(false)
         
            
        }.padding(20)
        
    }
}

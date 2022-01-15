//
//  ContentView.swift
//  YabaiIndicator
//
//  Created by Max Zhao on 26/12/2021.
//

import SwiftUI

struct SpaceButton : View {
    var space: Space
    
    func getText() -> String {
        switch space.type {
        case .standard:
            return "\(space.index)"
        case .fullscreen:
            return "F"
        case .divider:
            return ""
        }
    }
    
    func switchSpace() {
        if !space.active && space.yabaiIndex > 0 {
            gYabaiClient.focusSpace(index: space.yabaiIndex)
        }        
    }
    
    var body: some View {
        if space.type == .divider {
            Divider().background(Color(.systemGray)).frame(height: 14)
        } else {
            Image(nsImage: generateImage(symbol: getText() as NSString, active: space.active, visible: space.visible)).onTapGesture {
                switchSpace()
            }.frame(width:24, height: 16)
        }
    }
}

struct WindowSpaceButton : View {
    var space: Space
    var windows: [Window]
    var displays: [Display]
    
    func switchSpace() {
        if !space.active && space.yabaiIndex > 0 {
            gYabaiClient.focusSpace(index: space.yabaiIndex)
        }
    }
    
    var body : some View {
        switch space.type {
        case .standard:
            Image(nsImage: generateImage(active: space.active, visible: space.visible, windows: windows, display: displays[space.display-1])).onTapGesture {
                switchSpace()
            }.frame(width:24, height: 16)
        case .fullscreen:
            Image(nsImage: generateImage(symbol: "F" as NSString, active: space.active, visible: space.visible)).onTapGesture {
                switchSpace()
            }
        case .divider:
            Divider().background(Color(.systemGray)).frame(height: 14)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var spaceModel: SpaceModel
    @AppStorage("showDisplaySeparator") private var showDisplaySeparator = true
    @AppStorage("showCurrentSpaceOnly") private var showCurrentSpaceOnly = false
    @AppStorage("buttonStyle") private var buttonStyle: ButtonStyle = .numeric
    
    private func generateSpaces() -> [Space] {
        var shownSpaces:[Space] = []
        var lastDisplay = 0
        for space in spaceModel.spaces {
            if lastDisplay > 0 && space.display != lastDisplay {
                if showDisplaySeparator {
                    shownSpaces.append(Space(spaceid: 0, uuid: "", visible: true, active: false, display: 0, index: 0, yabaiIndex: 0, type: .divider))
                }
            }
            if space.visible || !showCurrentSpaceOnly{
                shownSpaces.append(space)
            }
            lastDisplay = space.display
        }
        return shownSpaces
    }
    
    var body: some View {
        HStack (spacing: 4) {
            if buttonStyle == .numeric || spaceModel.displays.count > 0 {
                ForEach(generateSpaces(), id: \.self) {space in
                    switch buttonStyle {
                    case .numeric:
                        SpaceButton(space: space)
                    case .windows:
                        WindowSpaceButton(space: space, windows: spaceModel.windows.filter{$0.spaceIndex == space.yabaiIndex}, displays: spaceModel.displays)
                    }
                }
            }
        }.padding(2)
    }
}

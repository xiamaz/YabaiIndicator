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
        if space.type == 0 {
            return "\(space.index)"
        } else if space.type == 4 {
            return "F"
        } else {
            return "?"
        }
    }
    
    func switchSpace() {
        if !space.active && space.yabaiIndex > 0 {
            gYabaiClient.focusSpace(index: space.yabaiIndex)
        }        
    }
    
    var body: some View {
        if space.type == -1 {
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
    var display: Display
    
    func switchSpace() {
        if !space.active && space.yabaiIndex > 0 {
            gYabaiClient.focusSpace(index: space.yabaiIndex)
        }
    }
    
    var body : some View {
        Image(nsImage: generateImage(active: space.active, visible: space.visible, windows: windows, display: display)).onTapGesture {
            switchSpace()
        }.frame(width:24, height: 16)
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
                    shownSpaces.append(Space(id: 0, uuid: "", visible: true, active: false, display: 0, index: 0, yabaiIndex: 0, type: -1))
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
                ForEach(generateSpaces()) {space in
                    switch buttonStyle {
                    case .numeric:
                        SpaceButton(space: space)
                    case .windows:
                        WindowSpaceButton(space: space, windows: spaceModel.windows.filter{$0.spaceIndex == space.index}, display: spaceModel.displays[space.display-1])
                    }
                }
            }
        }.padding(2)
    }
}

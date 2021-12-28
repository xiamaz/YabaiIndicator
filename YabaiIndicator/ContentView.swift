//
//  ContentView.swift
//  YabaiIndicator
//
//  Created by Max Zhao on 26/12/2021.
//

import SwiftUI

struct SpaceButtonStyle: ButtonStyle {
    let active: Bool
    let visible: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 22, height: 16)
            .padding(1)
            .foregroundColor(active ? Color(NSColor.windowBackgroundColor) : visible ? Color(.systemGray) : .primary)
            .background(active ? Color.primary: visible ? .primary : Color.clear)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary, lineWidth: 1))
    }
}

@discardableResult
func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/local/bin/yabai"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

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
    
    func switchSpace(index: Int) {
        if !space.active && index > 0 {
            shell(
                "-m", "space", "--focus", "\(index)")
        }
        
    }
    
    var body: some View {
        if space.type == -1 {
            Divider().background(Color(.systemGray)).frame(height: 14)
        } else {
            Button(
                action: {switchSpace(index: space.yabaiIndex)}
            ){
                Text("\(getText())")
                    .frame(width: 22, height: 16)
                    .contentShape(Rectangle()) // Add this line

            }.buttonStyle(SpaceButtonStyle(active: space.active, visible: space.visible))

        }
    }
}

struct ContentView: View {
    
    @EnvironmentObject var spaces: Spaces
    
    
    var body: some View {
        HStack (spacing: 4) {
            ForEach(spaces.spaceElems) {space in
                SpaceButton(space: space)
            }
        }.frame(height: 18)
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView().environmentObject(Spaces(spaces:[]))
    }
}

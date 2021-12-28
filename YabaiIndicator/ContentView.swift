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
            .frame(width: 22)
            .padding(1)
            .foregroundColor(active ? Color(NSColor.windowBackgroundColor) : visible ? Color(.systemGray) : .primary)
            .background(active ? Color.primary: visible ? .primary : Color.clear)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary, lineWidth: 1)
               )
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
    
    func switchSpace(index: Int) {
        if !space.active {
            shell(
                "-m", "space", "--focus", "\(index)")
        }
        
    }
    
    var body: some View {
        if space.index == 0 {
            Divider().background(Color(.systemGray)).frame(height: 14)
        } else {
            Button(
                action: {switchSpace(index: space.index)}
            ){
                Text("\(space.index)")
                    .frame(width: 22)
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
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView().environmentObject(Spaces(spaces:[]))
    }
}

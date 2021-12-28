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
            .foregroundColor(active ? .black : visible ? .gray : .primary)
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

struct ContentView: View {
    
    @EnvironmentObject var spaces: Spaces
    
    func switchSpace(index: Int) {
        if index != spaces.activeSpace {
            shell(
                "-m", "space", "--focus", "\(index)")
        }
        
    }
    
    var body: some View {
        HStack (spacing: 5) {
            ForEach(spaces.allSpaces, id: \.self) {space in
                Button(
                    action: {switchSpace(index: space)}
                ){
                    Text("\(space)")
                        .frame(width: 22)
                        .contentShape(Rectangle()) // Add this line

                }.buttonStyle(SpaceButtonStyle(active: space == spaces.activeSpace, visible: spaces.visibleSpaces.contains(space)))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView().environmentObject(Spaces())
    }
}

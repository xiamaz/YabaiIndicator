//
//  ContentView.swift
//  YabaiIndicator
//
//  Created by Max Zhao on 26/12/2021.
//

import SwiftUI

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
    
    func switchSpace() {
        if !space.active && space.yabaiIndex > 0 {
            shell(
                "-m", "space", "--focus", "\(space.yabaiIndex)")
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

struct ContentView: View {
    
    @EnvironmentObject var spaces: Spaces
    
    
    var body: some View {
        HStack (spacing: 4) {
            ForEach(spaces.spaceElems) {space in
                SpaceButton(space: space)
            }
        }.padding(2)
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView().environmentObject(Spaces(spaces:[]))
    }
}

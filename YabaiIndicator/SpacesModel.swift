//
//  SpacesModel.swift
//  YabaiIndicator
//
//  Created by Max Zhao on 27/12/2021.
//

import Foundation

class Spaces: ObservableObject {
    @Published var spaceElems:[Space] = []
    
    init(spaces: [Space]) {
        spaceElems = spaces
    }    
}

struct Space: Identifiable {
    let id: UInt64
    let uuid: String
    let visible: Bool
    let active: Bool
    let displayUUID: String
    let index: Int // mission control index (for sanitys sake)
    let yabaiIndex: Int // continuous index (for addresssing)
    let type: Int // 0 - normal space 4 - fullscreen space // -1 divider
    // var id: String { uuid }
}

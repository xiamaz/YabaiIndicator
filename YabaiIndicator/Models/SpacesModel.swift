//
//  SpacesModel.swift
//  YabaiIndicator
//
//  Created by Max Zhao on 27/12/2021.
//

import Foundation

class SpaceModel: ObservableObject {
    @Published var spaces:[Space] = []
    @Published var windows:[Window] = []
    @Published var displays:[Display] = []
}

struct Space: Hashable {
    let spaceid: UInt64
    let uuid: String
    let visible: Bool
    let active: Bool
    let display: Int
    let index: Int // mission control index (for sanitys sake)
    let yabaiIndex: Int // continuous index (for addresssing)
    let type: SpaceType // 0 - normal space 4 - fullscreen space // -1 divider
    // var id: String { uuid }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(spaceid)
        hasher.combine(visible)
        hasher.combine(active)
        hasher.combine(display)
        hasher.combine(index)
    }
}

struct Display: Identifiable {
    let id: UInt64
    let uuid: String
    let index: Int
    let frame: NSRect
}

struct Window: Identifiable {
    let id: UInt64
    let pid: UInt64
    let app: String
    let title: String
    let frame: NSRect
    let displayIndex: Int
    let spaceIndex: Int
}

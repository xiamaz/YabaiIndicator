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
    let uuid: String
    let visible: Bool
    let active: Bool
    let displayUUID: String
    let index: Int
    var id: String { uuid }
}

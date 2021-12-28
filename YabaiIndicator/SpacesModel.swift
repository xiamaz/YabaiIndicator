//
//  SpacesModel.swift
//  YabaiIndicator
//
//  Created by Max Zhao on 27/12/2021.
//

import Foundation

class Spaces: ObservableObject {
    @Published var activeSpace:Int = 0
    @Published var visibleSpaces:[Int] = []
    @Published var allSpaces:[Int] = []
}

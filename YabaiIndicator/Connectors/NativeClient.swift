//
//  NativeClient.swift
//  YabaiIndicator
//
//  Created by Max Zhao on 03/01/2022.
//

import Foundation
import ColorSync

class NativeClient {
    let gConnection = SLSMainConnectionID()
    
    /**
    Return a list of spaces without using Yabai
     */
    func querySpaces() -> [Space] {
        let activeDisplayUUID = SLSCopyActiveMenuBarDisplayIdentifier(gConnection).takeRetainedValue() as String

        let displays = SLSCopyManagedDisplaySpaces(gConnection).takeRetainedValue() as [AnyObject]

        var spaceIncr = 0
        var totalSpaces = 0
        var spaces:[Space] = []
        for (dindex, display) in displays.enumerated() {
            let displaySpaces = display["Spaces"] as? [NSDictionary] ?? []
            let current = display["Current Space"] as? NSDictionary
            // let currentUUID = current["uuid"] as? String
            let currentUUID = current?["uuid"] as? String ?? ""
            let displayUUID = display["Display Identifier"] as? String ?? ""
            let activeDisplay = activeDisplayUUID == displayUUID
            
            for nsSpace:NSDictionary in displaySpaces {
                let spaceId = nsSpace["id64"] as? UInt64 ?? 0
                let spaceUUID = nsSpace["uuid"] as? String ?? ""
                let visible = spaceUUID == currentUUID
                let active = visible && activeDisplay
                let spaceType = nsSpace["type"] as? Int ?? 0
                
                var spaceIndex = 0
                totalSpaces += 1
                if spaceType == 0 {
                    spaceIncr += 1
                    spaceIndex = spaceIncr
                }
                
                spaces.append(Space(spaceid: spaceId, uuid: spaceUUID, visible: visible, active: active, display: dindex + 1, index: spaceIndex, yabaiIndex: totalSpaces, type: SpaceType(rawValue: spaceType) ?? SpaceType.standard))
            }
        }
        return spaces
    }
    
    func queryDisplays() -> [Display] {
        let rawUuids = SLSCopyManagedDisplays(gConnection).takeRetainedValue() as? [CFString];
        
        var displays:[Display] = []
        if let uuids = rawUuids {
            for (i, displayUuid) in uuids.enumerated() {
                let cfuuid = CFUUIDCreateFromString(nil, displayUuid)
                let did = CGDisplayGetDisplayIDFromUUID(cfuuid)
                let bounds = CGDisplayBounds(did)
                displays.append(Display(id: UInt64(did), uuid: displayUuid as String, index: i, frame: bounds))
            }
        }
        return displays
    }
}

let gNativeClient = NativeClient()

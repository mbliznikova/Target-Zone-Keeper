//
//  Settings.swift
//  targetZoneKeeper
//
//  Created by Margarita Bliznikova on 5/15/24.
//

import Foundation
import SwiftUI

class Settings {
    
    var ifInZoneHaptics: Bool = false
    
    var belowZoneColor: [String: Float] = [:]
    var inZoneColor: [String: Float] = [:]
    var aboveZoneColor: [String: Float] = [:]
    
    var fasterHaptic: Haptics = Haptics.success
    var slowerHaptic: Haptics = Haptics.stop
    var inZoneHaptic: Haptics = Haptics.notification
    
    enum Haptics {
        case notification
        case directionUp
        case directionDown
        case success
        case failure
        case retry
        case start
        case stop
        case click
        case navigationGenericManeuver
        case navigationLeftTurn
        case navigationRightTurn
    }
    
    func makeDictionaryToTransfer() -> [String: Any] {
        return [
            "InZoneHaptics": ifInZoneHaptics,
            "belowZoneColor": belowZoneColor,
            "inZoneColor": inZoneColor,
            "aboveZoneColor": aboveZoneColor,
            //TODO: handle configurable haptics
//            "fasterHaptic": fasterHaptic,
//            "slowerHaptic": slowerHaptic,
//            "inZoneHaptic": inZoneHaptic
        ]
    }
}

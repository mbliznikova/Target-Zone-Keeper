//
//  Settings.swift
//  targetZoneKeeper
//
//  Created by Margarita Bliznikova on 5/15/24.
//

import Foundation
import SwiftUI


struct ColorSetting {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    func toDictionary() -> [String: Any] {
        return [
            "red": red,
            "green": green,
            "blue": blue,
            "opacity": opacity,
        ]
    }

    static func fromDictionary(input: [String: Any]) -> ColorSetting {
        //TODO: Check if `... as? Double` evaluate to nil, and write to log if it is
        let red = (input["red"] as? Double) ?? 0.0
        let green = (input["green"] as? Double) ?? 0.0
        let blue = (input["blue"] as? Double) ?? 0.0
        let opacity = (input["opacity"] as? Double) ?? 0.0

        return ColorSetting(red: red, green: green, blue: blue, opacity: opacity)
    }

    func toStandardColor() -> Color {
        return Color(.sRGB, red: red, green: green, blue: blue)
    }
}

struct Haptics {

    enum HapticsTypes: String, CaseIterable, Identifiable {
        case start = "Single tap"
        case stop = "Double slow tap"
        case directionUp = "Double fast tap"
        case success = "Fast tap series"
        case notification = "Tap + vibration"
        case retry = "Long vibration"

        var id: Self {
            self
        }
    }

    static func fromRawValue(raw: String) -> HapticsTypes {
        return Haptics.HapticsTypes(rawValue: raw) ?? .success
    }
}


class Settings {

    var ifInZoneHaptics: Bool = false

    var belowZoneColor: ColorSetting = ColorSetting(red: 0.96, green: 0.8, blue: 0.27, opacity: 1.0)
    var inZoneColor: ColorSetting = ColorSetting(red: 0.39, green: 0.76, blue: 0.4, opacity: 1.0)
    var aboveZoneColor: ColorSetting = ColorSetting(red: 0.15, green: 0.3, blue: 1.5, opacity: 1.0)

    var fasterHaptic: Haptics.HapticsTypes = .success
    var inZoneHaptic: Haptics.HapticsTypes = .notification
    var slowerHaptic: Haptics.HapticsTypes = .stop

    var isTestHaptic: Bool = false
    var currentHaptic: Haptics.HapticsTypes = .success

    func toDictionary() -> [String: Any] {
        return [
            "InZoneHaptics": ifInZoneHaptics,
            "belowZoneColor": belowZoneColor.toDictionary(),
            "inZoneColor": inZoneColor.toDictionary(),
            "aboveZoneColor": aboveZoneColor.toDictionary(),
            "fasterHaptic": fasterHaptic.rawValue,
            "slowerHaptic": slowerHaptic.rawValue,
            "inZoneHaptic": inZoneHaptic.rawValue,
            "isTestHaptic": isTestHaptic,
            "currentHaptic": currentHaptic.rawValue
        ]
    }

    static func fromDictionary(input: [String: Any]) -> Settings {
        //TODO: Check if `... as? [String: Any]` evaluate to nil, and write to log if it is
        //TODO: make function that will help with unwrapping and logging
        let result = Settings()
        result.ifInZoneHaptics = (input["InZoneHaptics"] as? Bool) ?? true;
        result.belowZoneColor = ColorSetting.fromDictionary(input: (input["belowZoneColor"] as? [String: Any]) ?? [:])
        result.inZoneColor = ColorSetting.fromDictionary(input: (input["inZoneColor"] as? [String: Any]) ?? [:])
        result.aboveZoneColor = ColorSetting.fromDictionary(input: (input["aboveZoneColor"] as? [String: Any]) ?? [:])
        result.fasterHaptic = Haptics.fromRawValue(raw: input["fasterHaptic"] as? String ?? "success")
        result.inZoneHaptic = Haptics.fromRawValue(raw: input["inZoneHaptic"] as? String ?? "notification")
        result.slowerHaptic = Haptics.fromRawValue(raw: input["slowerHapticc"] as? String ?? "stop")
        result.isTestHaptic = (input["isTestHaptic"] as? Bool) ?? false
        result.currentHaptic = Haptics.fromRawValue(raw: input["currentHaptic"] as? String ?? "success")
        return result
    }
}

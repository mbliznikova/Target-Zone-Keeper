//
//  Settings.swift
//  targetZoneKeeper
//
//  Created by Margarita Bliznikova on 5/15/24.
//

import Foundation
import SwiftUI


struct TimestampedValue<Value>: Encodable, Decodable, Equatable where Value: Encodable, Value: Decodable, Value: Equatable {

    var value: Value
    var timestamp: Date

    init(value: Value, timestamp: Date) {
        self.value = value
        self.timestamp = timestamp
    }

    init(value: Value) {
        self.init(value: value, timestamp: Date())
    }

    func merge(other: Self) -> Self {
        if self.timestamp >= other.timestamp {
            return self
        }
        return other
    }

    mutating func update(value: Value) {
        self.value = value
        self.updateTime()
    }

    mutating func updateTime() {
        self.timestamp = Date()
    }
}

struct ColorSetting: Encodable, Decodable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    func toStandardColor() -> Color {
        return Color(.sRGB, red: red, green: green, blue: blue)
    }
}

enum Haptics: String, CaseIterable, Identifiable, Encodable, Decodable {
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

enum HeartRateZone: String, CaseIterable, Identifiable, Encodable, Decodable {
    case zone1 = "Zone 1: < 60%"
    case zone2 = "Zone 2: 60-70%"
    case zone3 = "Zone 3: 70-80%"
    case zone4 = "Zone 4: 80-90%"
    case zone5 = "Zone 5: > 90%"

    var id: Self {
        self
    }
}

final class Settings: Encodable, Decodable {
    typealias TimestampedHeartRateZone = TimestampedValue<HeartRateZone>
    typealias TimestampedBool = TimestampedValue<Bool>
    typealias TimestampedColorSetting = TimestampedValue<ColorSetting>
    typealias TimestampedHaptics = TimestampedValue<Haptics>

    var heartRateZone: TimestampedHeartRateZone = TimestampedHeartRateZone(value: HeartRateZone.zone3)

    var ifInZoneHaptics: TimestampedBool = TimestampedBool(value: true)

    var belowZoneColor: TimestampedColorSetting = TimestampedColorSetting(value: ColorSetting(red: 0.96, green: 0.8, blue: 0.27, opacity: 1.0))
    var inZoneColor: TimestampedColorSetting = TimestampedColorSetting(value: ColorSetting(red: 0.39, green: 0.76, blue: 0.4, opacity: 1.0))
    var aboveZoneColor: TimestampedColorSetting = TimestampedColorSetting(value: ColorSetting(red: 0.15, green: 0.3, blue: 1.5, opacity: 1.0))

    var fasterHaptic: TimestampedHaptics = TimestampedHaptics(value: .success)
    var inZoneHaptic: TimestampedHaptics = TimestampedHaptics(value: .notification)
    var slowerHaptic: TimestampedHaptics = TimestampedHaptics(value: .stop)

    func merge(other: Settings) -> Settings {
        let result = Settings()
        result.ifInZoneHaptics = ifInZoneHaptics.merge(other: other.ifInZoneHaptics)
        result.belowZoneColor = belowZoneColor.merge(other: other.belowZoneColor)
        result.inZoneColor = inZoneColor.merge(other: other.inZoneColor)
        result.aboveZoneColor = aboveZoneColor.merge(other: other.aboveZoneColor)
        result.fasterHaptic = fasterHaptic.merge(other: other.fasterHaptic)
        result.inZoneHaptic = inZoneHaptic.merge(other: other.inZoneHaptic)
        result.slowerHaptic = slowerHaptic.merge(other: other.slowerHaptic)
        result.heartRateZone = heartRateZone.merge(other: other.heartRateZone)
        return result
    }

    enum CodingKeys: String, CodingKey {
        case ifInZoneHaptics
        case belowZoneColor
        case inZoneColor
        case aboveZoneColor
        case fasterHaptic
        case inZoneHaptic
        case slowerHaptic
        case heartRateZone
    }

    static func extractFromUserInfo(userInfo: [String: Any]) throws -> Settings {
        guard let settingsWithAnyType = userInfo["settings"] else {
            throw NSError(domain: "tzk_settings_missing", code: 1)
        }

        guard let settingsData = settingsWithAnyType as? Data else {
            throw NSError(domain: "tzk_settings_not_data", code: 1)
        }

        let jsonDecoder = JSONDecoder()
        let result = try jsonDecoder.decode(Settings.self, from: settingsData)
        return result
    }

    func saveToUserDefaults() {
        do {
         let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(self) {
                UserDefaults.standard.set(encoded, forKey: "settings")
            }
        }
    }

}

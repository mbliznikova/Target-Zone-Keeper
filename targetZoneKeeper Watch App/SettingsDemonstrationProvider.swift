//
//  TryHaptic.swift
//  targetZoneKeeper Watch App
//
//  Created by Margarita Bliznikova on 5/23/24.
//

import Foundation
import WatchKit

class SettingsDemonstrationProvider: ObservableObject {

    @Published var isDemoRunning: Bool = false

    @Published var haptic: WKHapticType = .success
    @Published var hapticName: String = ""

    var phoneData = ConnectionProviderWatch.shared

    init() {
        phoneData.settingsDemonstration = self
    }
}

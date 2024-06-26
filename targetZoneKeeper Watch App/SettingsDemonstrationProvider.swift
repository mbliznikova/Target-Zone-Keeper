//
//  TryHaptic.swift
//  targetZoneKeeper Watch App
//
//  Created by Margarita Bliznikova on 5/23/24.
//

import Foundation
import WatchKit

class SettingsDemonstrationProvider: ObservableObject {

    @Published var isHapticsListOpen: Bool = false

    var phoneData = ConnectionProviderWatch.shared

    @Published var currentHaptic: WKHapticType = .success
    @Published var currentHapticName: String = ""

    init() {
        phoneData.settingsDemonstration = self
    }
}

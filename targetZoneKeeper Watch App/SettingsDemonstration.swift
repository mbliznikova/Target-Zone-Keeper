//
//  TryHaptic.swift
//  targetZoneKeeper Watch App
//
//  Created by Margarita Bliznikova on 5/23/24.
//

import Foundation
import WatchKit

class SettingsDemonstration: ObservableObject {

    @Published var isHapticsListOpen: Bool = false

    var phoneData = WatchCommunication.shared

    @Published var currentHaptic: WKHapticType = .success
    @Published var currentHapticName: String = ""

    init() {
        phoneData.settingsDemonstration = self
    }
}

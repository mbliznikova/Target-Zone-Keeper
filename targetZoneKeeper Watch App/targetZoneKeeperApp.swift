//
//  targetZoneKeeperApp.swift
//  targetZoneKeeper Watch App
//
//  Created by Margarita Bliznikova on 4/25/24.
//

import SwiftUI

import Mixpanel

@main
struct targetZoneKeeper_Watch_AppApp: App {
    @StateObject var heartRateData: HeartRateController = HeartRateController()
    @StateObject var settingsDemonstration: SettingsDemonstrationProvider = SettingsDemonstrationProvider()

    init() {
        if let projectToken = ProcessInfo.processInfo.environment["MIX_PANEL_PROJECT_TOKEN"] {
            Mixpanel.initialize(token: projectToken) // TimeZoneKeeper Development
        } else {
            print("Can not initialize Mixpanel: no project token for Mixpanel in environment. Events will not be tracked.")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(heartRateController: heartRateData, settingsDemonstrationProvider: settingsDemonstration)
        }
    }
}

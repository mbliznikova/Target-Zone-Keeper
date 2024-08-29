//
//  targetZoneKeeperApp.swift
//  targetZoneKeeper
//
//  Created by Margarita Bliznikova on 4/25/24.
//

import SwiftUI

import Mixpanel

@main
struct targetZoneKeeperApp: App {
    @StateObject var settingsLoader: SettingsLoader = SettingsLoader()

    init() {
        if let projectToken = ProcessInfo.processInfo.environment["MIX_PANEL_PROJECT_TOKEN"] {
            Mixpanel.initialize(token: projectToken, trackAutomaticEvents: true) // TimeZoneKeeper Development
        } else {
            print("Can not initialize Mixpanel: no project token for Mixpanel in environment. Events will not be tracked.")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(settingsLoader: settingsLoader)
        }
    }
}

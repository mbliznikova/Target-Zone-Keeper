//
//  targetZoneKeeperApp.swift
//  targetZoneKeeper
//
//  Created by Margarita Bliznikova on 4/25/24.
//

import SwiftUI

@main
struct targetZoneKeeperApp: App {
    @StateObject var settingsLoader: SettingsLoader = SettingsLoader()
    var body: some Scene {
        WindowGroup {
            ContentView(settingsLoader: settingsLoader)
        }
    }
}

//
//  targetZoneKeeperApp.swift
//  targetZoneKeeper
//
//  Created by Margarita Bliznikova on 4/25/24.
//

import SwiftUI

@main
struct targetZoneKeeperApp: App {
    @StateObject var settingsData: Settings = Settings()
    var body: some Scene {
        WindowGroup {
            ContentView(settingsModel: settingsData)
        }
    }
}

//
//  SettingsLoader.swift
//  targetZoneKeeper
//
//  Created by Margarita Bliznikova on 6/21/24.
//

import Foundation

class SettingsLoader: ObservableObject {
    @Published var settings: Settings

    var watchData = ConnectionProviderPhone.shared

    init() {

        if let defaultSettings = UserDefaults.standard.data(forKey: "settings") {
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(Settings.self, from: defaultSettings)
                settings = decoded
            } catch {
                print("Error during decoding data from UserDefaults \(error)")
                settings = Settings()
            }
        } else {
            settings = Settings()
        }
        watchData.settingsLoader = self
    }
}

//
//  targetZoneKeeperApp.swift
//  targetZoneKeeper Watch App
//
//  Created by Margarita Bliznikova on 4/25/24.
//

import SwiftUI

@main
struct targetZoneKeeper_Watch_AppApp: App {
    @StateObject var heartRateData: HeartRateData = HeartRateData()
    
    var body: some Scene {
        WindowGroup {
            ContentView(heartRateDataModel: heartRateData)
        }
    }
}

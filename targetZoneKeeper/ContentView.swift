//
//  ContentView.swift
//  targetZoneKeeper
//
//  Created by Margarita Bliznikova on 4/25/24.
//

import SwiftUI
import Combine

struct ContentView: View {

    @ObservedObject var settingsModel: Settings

    @Environment(\.self) var environment

    @AppStorage("ifInZoneHaptics") private var ifInZoneHaptics: Bool = false

    @State private var belowZoneColor = Color(red: 0.96, green: 0.8, blue: 0.27)
    @State private var inZoneColor = Color(red: 0.39, green: 0.76, blue: 0.4)
    @State private var aboveZoneColor = Color(red: 0.15, green: 0.3, blue: 1.5)

    @State private var fasterHaptic: Haptics.HapticsTypes = .success
    @State private var inZoneHaptic: Haptics.HapticsTypes = .notification
    @State private var slowerHaptic: Haptics.HapticsTypes = .stop

    var body: some View {

        NavigationStack(root: {
            Form {
                Section(header: Text("Set target zone"), content: {
                    VStack {
                        HStack {
                            Picker("Target Heart Rate zone", selection: $settingsModel.currentHeartRateZone.zone) {
                                ForEach(HeartRateZoneSettings.Zones.allCases) { value in
                                    Text(value.rawValue)
                                }
                            }
                            .onChange(of: settingsModel.currentHeartRateZone.zone, initial: false) {
                                settingsModel.currentHeartRateZone.latestUpdateDate = Date()
                                Communication.shared.sendToWatch(data: ["currentHeartRateZone": settingsModel.currentHeartRateZone.toDictionary()])

                                do {
                                 let encoder = JSONEncoder()
                                    if let encoded = try? encoder.encode(settingsModel.currentHeartRateZone) {
                                        UserDefaults.standard.set(encoded, forKey: "currentHeartRateZone")
                                    }
                                }

                            }
                            .pickerStyle(.wheel)

                        }
                        // TODO: check if annother device is reachable and session is active
                        Button(action: {
                            // TODO: send only the signal to start a workout?
                            Communication.shared.sendToWatch(data: ["currentHeartRateZone": settingsModel.currentHeartRateZone.toDictionary(), "workoutStarted": true])
                        }) {
                            Text("Start")
                                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                })

                Section(header: Text("Haptics"), content: {
                    NavigationLink(
                        destination: HapticTypesView(
                            zoneAlert: $fasterHaptic,
                            onSelect: {
                                settingsModel.fasterHaptic = fasterHaptic
                                settingsModel.isTestHaptic = true
                                settingsModel.currentHaptic = fasterHaptic
                                Communication.shared.sendToWatch(data: ["Settings" : settingsModel.toDictionary()])
                            }, onListDisappear: {
                                settingsModel.isTestHaptic = false
                                Communication.shared.sendToWatch(data: ["Settings" : settingsModel.toDictionary()])
                            }
                        )
                    )
                    {
                        HStack {
                            Text("Below zone alert")
                            Spacer()
                            Text("\(fasterHaptic.rawValue)")
                        }
                    }

                    NavigationLink(
                        destination: HapticTypesView(
                            zoneAlert: $inZoneHaptic,
                            onSelect: {
                                settingsModel.inZoneHaptic = inZoneHaptic
                                settingsModel.isTestHaptic = true
                                settingsModel.currentHaptic = inZoneHaptic
                                Communication.shared.sendToWatch(data: ["Settings" : settingsModel.toDictionary()])
                            }, onListDisappear: {
                                settingsModel.isTestHaptic = false
                                Communication.shared.sendToWatch(data: ["Settings" : settingsModel.toDictionary()])
                            }
                        )
                    ) {
                        HStack {
                            Text("In zone alert")
                            Spacer()
                            Text("\(inZoneHaptic.rawValue)")
                        }
                    }

                    NavigationLink(
                        destination: HapticTypesView(
                            zoneAlert: $slowerHaptic,
                            onSelect: {
                                settingsModel.slowerHaptic = slowerHaptic
                                settingsModel.isTestHaptic = true
                                settingsModel.currentHaptic = slowerHaptic
                                Communication.shared.sendToWatch(data: ["Settings" : settingsModel.toDictionary()])
                            }, onListDisappear: {
                                settingsModel.isTestHaptic = false
                                Communication.shared.sendToWatch(data: ["Settings" : settingsModel.toDictionary()])
                            }
                        )
                    ) {
                        HStack {
                            Text("Above zone alert")
                            Spacer()
                            Text("\(slowerHaptic.rawValue)")
                        }
                    }

                        Toggle("In-zone haptic alerts?", isOn: $ifInZoneHaptics)
                            .onChange(of: ifInZoneHaptics) {
                                settingsModel.ifInZoneHaptics = ifInZoneHaptics
                                let dictUserInfo = settingsModel.toDictionary()
                                Communication.shared.sendToWatch(data: ["Settings" : dictUserInfo])
                            }
                })

                Section(header: Text("Colors"), content: {
                    HStack { ColorPicker("Below target zone", selection: $belowZoneColor)
                            .onChange(of: belowZoneColor) {
                                let resolvedColor = belowZoneColor.resolve(in: environment)
                                settingsModel.belowZoneColor.red = Double(resolvedColor.red)
                                settingsModel.belowZoneColor.green = Double(resolvedColor.green)
                                settingsModel.belowZoneColor.blue = Double(resolvedColor.blue)
                                settingsModel.belowZoneColor.opacity = Double(resolvedColor.opacity)
                                let dictUserInfo = settingsModel.toDictionary()
                                Communication.shared.sendToWatch(data: ["Settings" : dictUserInfo])
                            }
                    }
                    HStack {
                        ColorPicker("In target zone", selection: $inZoneColor)
                            .onChange(of: inZoneColor) {
                                let resolvedColor = inZoneColor.resolve(in: environment)
                                settingsModel.inZoneColor.red = Double(resolvedColor.red)
                                settingsModel.inZoneColor.green = Double(resolvedColor.green)
                                settingsModel.inZoneColor.blue = Double(resolvedColor.blue)
                                settingsModel.inZoneColor.opacity = Double(resolvedColor.opacity)
                                let dictUserInfo = settingsModel.toDictionary()
                                Communication.shared.sendToWatch(data: ["Settings" : dictUserInfo])
                            }
                    }
                    HStack {
                        ColorPicker("Above target zone", selection: $aboveZoneColor)
                            .onChange(of: aboveZoneColor) {
                                let resolvedColor = aboveZoneColor.resolve(in: environment)
                                settingsModel.aboveZoneColor.red = Double(resolvedColor.red)
                                settingsModel.aboveZoneColor.green = Double(resolvedColor.green)
                                settingsModel.aboveZoneColor.blue = Double(resolvedColor.blue)
                                settingsModel.aboveZoneColor.opacity = Double(resolvedColor.opacity)
                                let dictUserInfo = settingsModel.toDictionary()
                                Communication.shared.sendToWatch(data: ["Settings" : dictUserInfo])
                            }
                    }
                })
            }
            .navigationTitle("Settings")
        })
    }
}

struct HapticTypesView: View {

    @Binding var zoneAlert: Haptics.HapticsTypes
    var onSelect: () -> Void
    var onListDisappear: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
            Form {
                ForEach(Haptics.HapticsTypes.allCases) { haptic in
                    Button(action: {
                        zoneAlert = haptic
                        onSelect()
                    })
                    {
                        HStack {
                            if zoneAlert == haptic {
                                Image(systemName: "checkmark")
                            }
                            let textColor: Color = colorScheme == .dark ? Color.white : Color.black
                            Text(haptic.rawValue)
                                .foregroundStyle(textColor)
                        }
                    }
                }
            }
            .onDisappear() {
                onListDisappear()
            }
    }
}

#Preview {
    ContentView(settingsModel: Settings())
}

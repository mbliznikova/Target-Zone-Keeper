//
//  ContentView.swift
//  targetZoneKeeper
//
//  Created by Margarita Bliznikova on 4/25/24.
//

import SwiftUI
import Combine

struct ContentView: View {

    @ObservedObject var settingsLoader: SettingsLoader

    @Environment(\.self) var environment

    @State private var belowZoneColor: Color
    @State private var inZoneColor: Color
    @State private var aboveZoneColor: Color

    func sendToWatchAndSave() {
        ConnectionProviderPhone.shared.sendSettingsToWatch(settings: settingsLoader.settings)
        settingsLoader.settings.saveToUserDefaults()
    }

    func resolveColor(color: Color) -> ColorSetting {
        let resolvedColor = color.resolve(in: environment)
        return ColorSetting(
            red: Double(resolvedColor.red),
            green: Double(resolvedColor.green),
            blue: Double(resolvedColor.blue),
            opacity: Double(resolvedColor.opacity))
    }

    init(settingsLoader: SettingsLoader) {
        self.settingsLoader = settingsLoader

        belowZoneColor = settingsLoader.settings.belowZoneColor.value.toStandardColor()
        inZoneColor = settingsLoader.settings.inZoneColor.value.toStandardColor()
        aboveZoneColor = settingsLoader.settings.aboveZoneColor.value.toStandardColor()

    }
    
    var body: some View {

        NavigationStack(root: {
            Form {
                Section(header: Text("Set target zone"), content: {
                    VStack {
                        HStack {
                            Picker("Target Heart Rate zone", selection: $settingsLoader.settings.heartRateZone.value) {
                                ForEach(HeartRateZone.allCases) { value in
                                    Text(value.rawValue)
                                }
                            }
                            .onChange(of: settingsLoader.settings.heartRateZone.value, initial: false) {
                                settingsLoader.settings.heartRateZone.updateTime()
                                sendToWatchAndSave()
                            }
                            .pickerStyle(.wheel)
                            
                        }
                        // TODO: check if another device is reachable and session is active
//                        Button(action: {
//                            //ConnectionProvider.shared.sendToWatch(data: ["workoutStarted": true])
//                        }) {
//                            Text("Start")
//                                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
//                        }
//                        .buttonStyle(.borderedProminent)
                    }
                })

                Section(header: Text("Haptics"), content: {
                    NavigationLink(
                        destination: HapticTypesView(
                            zoneAlert: $settingsLoader.settings.fasterHaptic.value,
                            onSelect: {
                                ConnectionProviderPhone.shared.sendHapticTestToWatch(haptic: settingsLoader.settings.fasterHaptic.value)
                            }, onListDisappear: {
                                settingsLoader.settings.fasterHaptic.updateTime()
                                sendToWatchAndSave()
                            }
                        )
                    )
                    {
                        HStack {
                            Text("Below zone alert")
                            Spacer()
                            Text("\(settingsLoader.settings.fasterHaptic.value.rawValue)")
                        }
                    }

                    NavigationLink(
                        destination: HapticTypesView(
                            zoneAlert: $settingsLoader.settings.inZoneHaptic.value,
                            onSelect: {
                                ConnectionProviderPhone.shared.sendHapticTestToWatch(haptic: settingsLoader.settings.inZoneHaptic.value)
                            }, onListDisappear: {
                                settingsLoader.settings.inZoneHaptic.updateTime()
                                sendToWatchAndSave()
                            }
                        )
                    ) {
                        HStack {
                            Text("In zone alert")
                            Spacer()
                            Text("\(settingsLoader.settings.inZoneHaptic.value.rawValue)")
                        }
                    }

                    NavigationLink(
                        destination: HapticTypesView(
                            zoneAlert: $settingsLoader.settings.slowerHaptic.value,
                            onSelect: {
                                ConnectionProviderPhone.shared.sendHapticTestToWatch(haptic: settingsLoader.settings.slowerHaptic.value)
                            }, onListDisappear: {
                                settingsLoader.settings.slowerHaptic.updateTime()
                                sendToWatchAndSave()
                            }
                        )
                    ) {
                        HStack {
                            Text("Above zone alert")
                            Spacer()
                            Text("\(settingsLoader.settings.slowerHaptic.value.rawValue)")
                        }
                    }

                    Toggle("In-zone haptic alerts?", isOn: $settingsLoader.settings.ifInZoneHaptics.value)
                        .onChange(of: settingsLoader.settings.ifInZoneHaptics.value) {
                            settingsLoader.settings.ifInZoneHaptics.updateTime()
                            sendToWatchAndSave()
                        }
                })

                Section(header: Text("Colors"), content: {
                    HStack { ColorPicker("Below target zone", selection: $belowZoneColor)
                            .onChange(of: belowZoneColor) {
                                settingsLoader.settings.belowZoneColor.update(value: resolveColor(color: belowZoneColor))
                                sendToWatchAndSave()
                            }
                    }
                    HStack {
                        ColorPicker("In target zone", selection: $inZoneColor)
                            .onChange(of: inZoneColor) {
                                settingsLoader.settings.inZoneColor.update(value: resolveColor(color: inZoneColor))
                                sendToWatchAndSave()
                            }
                    }
                    HStack {
                        ColorPicker("Above target zone", selection: $aboveZoneColor)
                            .onChange(of: aboveZoneColor) {
                                settingsLoader.settings.aboveZoneColor.update(value: resolveColor(color: aboveZoneColor))
                                sendToWatchAndSave()
                            }
                    }
                })
            }
            .navigationTitle("Settings")
        })
    }
}

struct HapticTypesView: View {

    @Binding var zoneAlert: Haptics
    var onSelect: () -> Void
    var onListDisappear: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Form {
            ForEach(Haptics.allCases) { haptic in
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
    ContentView(settingsLoader: SettingsLoader())
}

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
    
    //    @AppStorage("ifInZoneHaptics") private var ifInZoneHaptics: Bool = false
    
    @State private var belowZoneColor = Color(red: 0.96, green: 0.8, blue: 0.27)
    @State private var inZoneColor = Color(red: 0.39, green: 0.76, blue: 0.4)
    @State private var aboveZoneColor = Color(red: 0.15, green: 0.3, blue: 1.5)
    
    @State private var fasterHaptic: Haptics = .success
    @State private var inZoneHaptic: Haptics = .notification
    @State private var slowerHaptic: Haptics = .stop
    
    //    mutating func updateSettings(newSettings: Settings) {
    //        settingsModel = settingsModel.merge(other: newSettings)
    //    }
    
    func resolveColor(color: Color) -> ColorSetting {
        let resolvedColor = color.resolve(in: environment)
        return ColorSetting(
            red: Double(resolvedColor.red),
            green: Double(resolvedColor.green),
            blue: Double(resolvedColor.blue),
            opacity: Double(resolvedColor.opacity))
    }
    
    var body: some View {
        
        NavigationStack(root: {
            Form {
                Section(header: Text("Set target zone"), content: {
                    VStack {
                        HStack {
                            Picker("Target Heart Rate zone", selection: $settingsModel.heartRateZone.value) {
                                ForEach(HeartRateZone.allCases) { value in
                                    Text(value.rawValue)
                                }
                            }
                            .onChange(of: settingsModel.heartRateZone.value, initial: false) {
                                settingsModel.heartRateZone.timestamp = Date()
                                ConnectionProviderPhone.shared.sendSettingsToWatch(settings: settingsModel)
                                
                                do {
                                    let encoder = JSONEncoder()
                                    if let encoded = try? encoder.encode(settingsModel.heartRateZone) {
                                        UserDefaults.standard.set(encoded, forKey: "heartRateZone")
                                    }
                                }
                                
                            }
                            .pickerStyle(.wheel)
                            
                        }
                        // TODO: check if another device is reachable and session is active
                        Button(action: {
                            // TODO: send only the signal to start a workout?
                            //ConnectionProvider.shared.sendToWatch(data: ["workoutStarted": true])
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
                                print("====DEBUG===")
                                print("The settingsModel.fasterHaptic is \(settingsModel.fasterHaptic)")
                                ConnectionProviderPhone.shared.sendHapticTestToWatch(haptic: settingsModel.fasterHaptic.value)
                            }, onListDisappear: {
                                settingsModel.fasterHaptic.update(value: fasterHaptic)
                                ConnectionProviderPhone.shared.sendSettingsToWatch(settings: settingsModel)
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
                                ConnectionProviderPhone.shared.sendHapticTestToWatch(haptic: settingsModel.inZoneHaptic.value)
                            }, onListDisappear: {
                                settingsModel.fasterHaptic.timestamp = Date()
                                ConnectionProviderPhone.shared.sendSettingsToWatch(settings: settingsModel)
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
                                ConnectionProviderPhone.shared.sendHapticTestToWatch(haptic: settingsModel.slowerHaptic.value)
                            }, onListDisappear: {
                                settingsModel.fasterHaptic.timestamp = Date()
                                ConnectionProviderPhone.shared.sendSettingsToWatch(settings: settingsModel)
                            }
                        )
                    ) {
                        HStack {
                            Text("Above zone alert")
                            Spacer()
                            Text("\(slowerHaptic.rawValue)")
                        }
                    }
                    
                    Toggle("In-zone haptic alerts?", isOn: $settingsModel.ifInZoneHaptics.value)
                        .onChange(of: settingsModel.ifInZoneHaptics.value) {
                            settingsModel.ifInZoneHaptics.timestamp = Date()
                            ConnectionProviderPhone.shared.sendSettingsToWatch(settings: settingsModel)
                        }
                })
                
                Section(header: Text("Colors"), content: {
                    HStack { ColorPicker("Below target zone", selection: $belowZoneColor)
                            .onChange(of: belowZoneColor) {
                                settingsModel.belowZoneColor.update(value: resolveColor(color: belowZoneColor))
                                ConnectionProviderPhone.shared.sendSettingsToWatch(settings: settingsModel)
                            }
                    }
                    HStack {
                        ColorPicker("In target zone", selection: $inZoneColor)
                            .onChange(of: inZoneColor) {
                                settingsModel.inZoneColor.update(value: resolveColor(color: inZoneColor))
                                ConnectionProviderPhone.shared.sendSettingsToWatch(settings: settingsModel)
                            }
                    }
                    HStack {
                        ColorPicker("Above target zone", selection: $aboveZoneColor)
                            .onChange(of: aboveZoneColor) {
                                settingsModel.aboveZoneColor.update(value: resolveColor(color: aboveZoneColor))
                                ConnectionProviderPhone.shared.sendSettingsToWatch(settings: settingsModel)
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
    ContentView(settingsModel: Settings())
}

//
//  ContentView.swift
//  targetZoneKeeper
//
//  Created by Margarita Bliznikova on 4/25/24.
//

import SwiftUI
import Combine

enum ViewName {
    case start, settings
}

struct ContentView: View {

    @State private var lowerBoundary: Int = 60
    @State private var upperBoundary: Int = 90


    @Environment(\.self) var environment

    @State var settings = Settings()


    @State private var settingsInZoneHaptics: Bool = false

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
                        Spacer()

                        // TODO: sanitize the input: check for a valid range
                        HStack {
                            Text("Lower boundary")
                            TextField(
                                lowerBoundary == 0 ? "Lower boundary" : String(lowerBoundary),
                                value: $lowerBoundary,
                                formatter: NumberFormatter()
                            )
                            .keyboardType(.numberPad)
                            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification), perform: { obj in
                                if let textField = obj.object as? UITextField {
                                    textField.selectedTextRange = textField.textRange(
                                        from: textField.beginningOfDocument,
                                        to: textField.endOfDocument
                                    )
                                }
                            })
                            .onChange(of: lowerBoundary) { _, _ in
                                Communication.shared.sendToWatch(data: ["upper": upperBoundary, "lower": lowerBoundary])
                            }

                        }
                        Spacer()
                        HStack {
                            Text("Upper boundary")
                            TextField(
                                "",
                                value: $upperBoundary,
                                formatter: NumberFormatter()
                            )
                            .keyboardType(.numberPad)
                            //                .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification), perform: { obj in
                            //                    if let textField = obj.object as? UITextField {
                            //                        textField.selectedTextRange = textField.textRange(
                            //                            from: textField.beginningOfDocument,
                            //                            to: textField.endOfDocument
                            //                        )
                            //                    }
                            //                })
                            .onChange(of: upperBoundary) { _, _ in
                                Communication.shared.sendToWatch(data: ["upper": upperBoundary, "lower": lowerBoundary])
                            }

                        }

                        Spacer()

                        // TODO: check if annother device is reachable and session is active
                        Button(action: {
                            Communication.shared.sendToWatch(data: ["upper": upperBoundary, "lower": lowerBoundary, "workoutStarted": true])
                        }) {
                            Text("Start")
                                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                })

                Section(header: Text("Haptics"), content: {
                    NavigationLink(
                        destination: HapticTypesView(
                            zoneAlert: $fasterHaptic,
                            onSelect: {
                                settings.fasterHaptic = fasterHaptic
                                settings.isTestHaptic = true
                                settings.currentHaptic = fasterHaptic
                                Communication.shared.sendToWatch(data: ["Settings" : settings.toDictionary()])
                            }, onListDisappear: {
                                settings.isTestHaptic = false
                                Communication.shared.sendToWatch(data: ["Settings" : settings.toDictionary()])
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
                                settings.inZoneHaptic = inZoneHaptic
                                settings.isTestHaptic = true
                                settings.currentHaptic = inZoneHaptic
                                Communication.shared.sendToWatch(data: ["Settings" : settings.toDictionary()])
                            }, onListDisappear: {
                                settings.isTestHaptic = false
                                Communication.shared.sendToWatch(data: ["Settings" : settings.toDictionary()])
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
                                settings.slowerHaptic = slowerHaptic
                                settings.isTestHaptic = true
                                settings.currentHaptic = slowerHaptic
                                Communication.shared.sendToWatch(data: ["Settings" : settings.toDictionary()])
                            }, onListDisappear: {
                                settings.isTestHaptic = false
                                Communication.shared.sendToWatch(data: ["Settings" : settings.toDictionary()])
                            }
                        )
                    ) {
                        HStack {
                            Text("Above zone alert")
                            Spacer()
                            Text("\(slowerHaptic.rawValue)")
                        }
                    }

                        Toggle("In-zone haptic alerts?", isOn: $settings.ifInZoneHaptics)
                            .onChange(of: settings.ifInZoneHaptics) {
                                let dictUserInfo = settings.toDictionary()
                                Communication.shared.sendToWatch(data: ["Settings" : dictUserInfo])
                            }
                })

                Section(header: Text("Colors"), content: {
                    HStack { ColorPicker("Below target zone", selection: $belowZoneColor)
                            .onChange(of: belowZoneColor) {
                                let resolvedColor = belowZoneColor.resolve(in: environment)
                                settings.belowZoneColor.red = Double(resolvedColor.red)
                                settings.belowZoneColor.green = Double(resolvedColor.green)
                                settings.belowZoneColor.blue = Double(resolvedColor.blue)
                                settings.belowZoneColor.opacity = Double(resolvedColor.opacity)
                                let dictUserInfo = settings.toDictionary()
                                Communication.shared.sendToWatch(data: ["Settings" : dictUserInfo])
                            }
                    }
                    HStack {
                        ColorPicker("In target zone", selection: $inZoneColor)
                            .onChange(of: inZoneColor) {
                                let resolvedColor = inZoneColor.resolve(in: environment)
                                settings.inZoneColor.red = Double(resolvedColor.red)
                                settings.inZoneColor.green = Double(resolvedColor.green)
                                settings.inZoneColor.blue = Double(resolvedColor.blue)
                                settings.inZoneColor.opacity = Double(resolvedColor.opacity)
                                let dictUserInfo = settings.toDictionary()
                                Communication.shared.sendToWatch(data: ["Settings" : dictUserInfo])
                            }
                    }
                    HStack {
                        ColorPicker("Above target zone", selection: $aboveZoneColor)
                            .onChange(of: aboveZoneColor) {
                                let resolvedColor = aboveZoneColor.resolve(in: environment)
                                settings.aboveZoneColor.red = Double(resolvedColor.red)
                                settings.aboveZoneColor.green = Double(resolvedColor.green)
                                settings.aboveZoneColor.blue = Double(resolvedColor.blue)
                                settings.aboveZoneColor.opacity = Double(resolvedColor.opacity)
                                let dictUserInfo = settings.toDictionary()
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
    ContentView()
}

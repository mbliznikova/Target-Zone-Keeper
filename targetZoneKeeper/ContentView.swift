//
//  ContentView.swift
//  targetZoneKeeper
//
//  Created by Margarita Bliznikova on 4/25/24.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    @State private var currentView: String = "Start"

    var body: some View {
        if currentView == "Start" {
            TargetZoneView(currentView: $currentView)
        } else {
            SettingsView(currentView: $currentView)
        }
    }
}

struct TargetZoneView: View {

    @Binding var currentView: String

    var communication = Communication()
    
    @State private var lowerBoundary: Int = 60
    @State private var upperBoundary: Int = 90
    
    var body: some View {
        VStack {
            // TODO: sanitize the input: check for a valid range
            Text("Please enter your target zone boundaries")
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
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
                    communication.sendToWatch(data: ["upper": upperBoundary, "lower": lowerBoundary])
                }

            }
            .padding()
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
                    communication.sendToWatch(data: ["upper": upperBoundary, "lower": lowerBoundary])
                }
            }
            .padding()
            Text("The boundaries are: \(lowerBoundary) and \(upperBoundary)")
        }
        .padding()
        VStack {
            // TODO: check if annother device is reachable and session is active
            Button("Start", action: {
                communication.sendToWatch(data: ["upper": upperBoundary, "lower": lowerBoundary, "workoutStarted": true])
            })
        }

        Button("Settings", action: {currentView = "Settings"})
    }
}

struct SettingsView: View {

    @Environment(\.self) var environment

    var communication = Communication()
    @State var settings = Settings()

    @Binding var currentView: String

    @State private var settingsInZoneHaptics: Bool = false

    @State private var belowZoneColor = Color(red: 0.96, green: 0.8, blue: 0.27)
    @State private var inZoneColor = Color(red: 0.39, green: 0.76, blue: 0.4)
    @State private var aboveZoneColor = Color(red: 0.15, green: 0.3, blue: 1.5)

    @State private var fasterHaptic: String = "Success"
    @State private var slowerHaptic: String = "Stop"
    @State private var inZoneHaptic: String = "Notification"

    var body: some View {
        Text("Select application's settings")
            .font(.title)
            .fontWeight(.heavy)
   
        Divider()
        Text("Haptics")
            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
        VStack {
            VStack {
                HStack {
                    Text("Below target zone")
                    Picker("Below zone", selection: $fasterHaptic) {
                    }
                }
                HStack {
                    Text("Above target zone")
                    Picker("Below zone", selection: $slowerHaptic) {
                    }
                }
                HStack {
                    Text("In zone (if switched on)")
                    Picker("Below zone", selection: $inZoneHaptic) {
                    }
                }
            }

            Divider()
            Toggle("In-zone haptics?", isOn: $settings.ifInZoneHaptics)
                .onChange(of: settings.ifInZoneHaptics) {
                    let dictUserInfo = settings.makeDictionaryToTransfer()
                    communication.sendToWatch(data: ["Settings" : dictUserInfo])
                }
        }

        Divider()
        VStack {
            Text("Colors")
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
            ColorPicker("Below target zone", selection: $belowZoneColor)
                .onChange(of: belowZoneColor) {
                    let resolvedColor = belowZoneColor.resolve(in: environment)
                    settings.belowZoneColor["red"] = resolvedColor.red
                    settings.belowZoneColor["green"] = resolvedColor.green
                    settings.belowZoneColor["blue"] = resolvedColor.blue
                    settings.belowZoneColor["opacity"] = resolvedColor.opacity
                    let dictUserInfo = settings.makeDictionaryToTransfer()
                    communication.sendToWatch(data: ["Settings" : dictUserInfo])
                }
            ColorPicker("In target zone", selection: $inZoneColor)
                .onChange(of: inZoneColor) {
                    let resolvedColor = inZoneColor.resolve(in: environment)
                    settings.inZoneColor["red"] = resolvedColor.red
                    settings.inZoneColor["green"] = resolvedColor.green
                    settings.inZoneColor["blue"] = resolvedColor.blue
                    settings.inZoneColor["opacity"] = resolvedColor.opacity
                    let dictUserInfo = settings.makeDictionaryToTransfer()
                    communication.sendToWatch(data: ["Settings" : dictUserInfo])
                }
            ColorPicker("Above target zone", selection: $aboveZoneColor)
                .onChange(of: aboveZoneColor) {
                    let resolvedColor = aboveZoneColor.resolve(in: environment)
                    settings.aboveZoneColor["red"] = resolvedColor.red
                    settings.aboveZoneColor["green"] = resolvedColor.green
                    settings.aboveZoneColor["blue"] = resolvedColor.blue
                    settings.aboveZoneColor["opacity"] = resolvedColor.opacity
                    let dictUserInfo = settings.makeDictionaryToTransfer()
                    communication.sendToWatch(data: ["Settings" : dictUserInfo])
                }

        }

        Divider()
  
        Button("Back", action: {currentView = "Start"})
    }

}

#Preview {
    ContentView()
}


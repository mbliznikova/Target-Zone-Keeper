//
//  ContentView.swift
//  targetZoneKeeper Watch App
//
//  Created by Margarita Bliznikova on 4/25/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var heartRateController: HeartRateController
    @ObservedObject var settingsDemonstrationModel: SettingsDemonstrationProvider

    @State var currentView: String = "welcome"
    
    func formatHeartRateBoundariesText() -> String {
        let boundaries = heartRateController.calculateZoneBoundaries()
        return "\(boundaries.lower) - \(boundaries.upper)"
    }

    var body: some View {

        switch currentView {
        case "welcome":
            if !heartRateController.isWorkoutStarted {
                    VStack {
                        Picker("", selection: $heartRateController.settings.heartRateZone.value) {
                            ForEach(HeartRateZone.allCases) { value in
                                Text("\(value.rawValue)")
                            }
                        }
                        .onChange(of: heartRateController.settings.heartRateZone.value, initial: false) {
                            heartRateController.settings.heartRateZone.timestamp = Date()
                            ConnectionProviderWatch.shared.sendSettings(settings: heartRateController.settings)
                            heartRateController.settings.saveToUserDefaults()
                        }
                        .pickerStyle(.wheel)
                        Spacer()
                        Text(formatHeartRateBoundariesText())
                        Spacer()
                        Button("START") {
                            currentView = "main"
                        }
                    }
                    .padding()
            } else {
                Text("Measuring heart rate...")
                    .onAppear(perform: {currentView = "main"})
            }
        case "test":
            VStack {
                HStack {
                    Text("Demonstarting")
                }
                Button("Back") {
                    currentView = "welcome"
                }
            }
        case "main":
            VStack{
                if heartRateController.heartRate == 0 {
                    Text("Measuring heart rate...")
                } else {
                    Text("\(heartRateController.heartRate)\n")
                        .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        //TODO: handle the text color
                        .foregroundStyle(heartRateController.color == .blue ? .white : .black)
                }
                Text("\(heartRateController.message)")
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    //TODO: handle the text color
                    .foregroundStyle(heartRateController.color == .blue ? .white : .black)
            }
            .onAppear(perform: {
                heartRateController.startWorkout()
                heartRateController.startTimer()
            })
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                heartRateController.color
                    .ignoresSafeArea()
            }
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        // Horizontal swipe
                        if abs(value.translation.width) > abs(value.translation.height) {
                            if value.translation.width < 0 {
                                // Left swipe
                                currentView = "stop"
                            }
                        }
                    }
            )
        case "stop":
            VStack{
                Spacer()
                Button("STOP") {
                    heartRateController.stopActivity()
                    currentView = "welcome"
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color.black
                    .ignoresSafeArea()
            }
            .gesture(
                // TODO: Debug why gesture doesn't work here
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            // TODO: Handle this better
                            if value.translation.width < 0 {
                                print("Left swipe")
                            } else {
                                print("Right swipe")
                                currentView = "main"
                            }
                        }
                    }
            )
        default:
            Text("I'm just a stub")
        }
    }
}


#Preview {
    ContentView(heartRateController: HeartRateController(), settingsDemonstrationModel: SettingsDemonstrationProvider())
}

//
//  ContentView.swift
//  targetZoneKeeper Watch App
//
//  Created by Margarita Bliznikova on 4/25/24.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var heartRateDataModel: HeartRateData
    @State var currentView: String = "welcome"
    
    @State var isWorkoutStarted: Bool = false
    
    var body: some View {
        
        switch currentView {
        case "welcome":
            if !heartRateDataModel.isWorkoutStarted {
                VStack {
                    Text("Target Zone")
                        .foregroundStyle(.blue)
                    Text("\(heartRateDataModel.lowerBoundary) - \(heartRateDataModel.upperBoundary)\n\n")
                        .foregroundStyle(.blue)
                    Button("START") {
                        currentView = "main"
                    }
                }
                .padding()
            } else {
                Text("Measuring heart rate...")
                    .onAppear(perform: {currentView = "main"})
            }
        case "main":
            VStack{
                if heartRateDataModel.heartRate == 0 {
                    Text("Measuring heart rate...")
                } else {
                    Text("\(heartRateDataModel.heartRate)\n")
                        .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        .foregroundStyle(heartRateDataModel.color == .blue ? .white : .black)
                }
                Text("\(heartRateDataModel.message)")
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .foregroundStyle(heartRateDataModel.color == .blue ? .white : .black)
            }
            .onAppear(perform: {
                heartRateDataModel.startWorkout()
                heartRateDataModel.startTimer()
            })
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                heartRateDataModel.color
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
                    heartRateDataModel.stopActivity()
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
    ContentView(heartRateDataModel: HeartRateData())
}

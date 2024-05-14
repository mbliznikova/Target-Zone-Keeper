//
//  ContentView.swift
//  targetZoneKeeper
//
//  Created by Margarita Bliznikova on 4/25/24.
//

import SwiftUI
import Combine

struct ContentView: View {
    
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
        }
    }

#Preview {
    ContentView()
}


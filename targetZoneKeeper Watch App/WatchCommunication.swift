//
//  WatchCommunication.swift
//  targetZoneKeeper Watch App
//
//  Created by Margarita Bliznikova on 4/29/24.
//

import Foundation
import WatchConnectivity
import SwiftUI

class WatchCommunication: NSObject, WCSessionDelegate {
    
    var heartRate: HeartRateData? = nil
    
    var mySession: WCSession
    
    
    // Session activation
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        if error != nil {
            print("WatchCommunication: the error is \(String(describing: error))")
        }
    }
    
    // This method is triggered by receiving a UserInfo
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        print("Getting data from the phone...")
        print("userInfo is \(userInfo)")
        Task { @MainActor in
            if userInfo["lower"] != nil {
                let tempLower = userInfo["lower"] as! Int?
                let tempUpper = userInfo["upper"] as! Int?
                let tempIsWorkout = userInfo["workoutStarted"] as! Bool?
                self.heartRate?.lowerBoundary = tempLower!
                self.heartRate?.upperBoundary = tempUpper!
                self.heartRate?.isWorkoutStarted = tempIsWorkout ?? false
            } else {
                if userInfo["Settings"] != nil {
                    let tempSettings = userInfo["Settings"] as! Dictionary<String, Any>?

                    let tempInZoneHaptic = tempSettings!["InZoneHaptics"] as! Bool?

                    let tempBelowZoneColor = tempSettings!["belowZoneColor"] as! [String: Float]?
                    let tempInZoneColor = tempSettings!["inZoneColor"] as! [String: Float]?
                    let tempAboveZoneColor = tempSettings!["aboveZoneColor"] as! [String: Float]?

                    self.heartRate?.inZoneHaptic = (tempInZoneHaptic != nil ? tempInZoneHaptic : self.heartRate?.inZoneHaptic)!

                    self.heartRate?.belowZoneColor = Color(.sRGB, red: Double(tempBelowZoneColor!["red"]!), green: Double(tempBelowZoneColor!["green"]!), blue: Double(tempBelowZoneColor!["blue"]!))
                    self.heartRate?.inZoneColor = Color(.sRGB, red: Double(tempInZoneColor!["red"]!), green: Double(tempInZoneColor!["green"]!), blue: Double(tempInZoneColor!["blue"]!))
                    self.heartRate?.aboveZoneColor = Color(.sRGB, red: Double(tempAboveZoneColor!["red"]!), green: Double(tempAboveZoneColor!["green"]!), blue: Double(tempAboveZoneColor!["blue"]!))
                }

            }

        }
    }

    override init() {
        self.mySession = WCSession.default
        print("WatchCommunication: Initializing Watch Communication")
        super.init()
        assert(WCSession.isSupported(), "WatchCommunication: WCSession should be supported")
        self.mySession.delegate = self
        self.mySession.activate()
        print("WatchCommunication: WCSession is activated")
    }
    
    
}


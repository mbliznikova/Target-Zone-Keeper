//
//  WatchCommunication.swift
//  targetZoneKeeper Watch App
//
//  Created by Margarita Bliznikova on 4/29/24.
//

import Foundation
import WatchConnectivity

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
        Task { @MainActor in
            let tempLower = userInfo["lower"] as! Int?
            let tempUpper = userInfo["upper"] as! Int?
            let tempIsWorkout = userInfo["workoutStarted"] as! Bool?
            self.heartRate?.lowerBoundary = tempLower!
            self.heartRate?.upperBoundary = tempUpper!
            self.heartRate?.isWorkoutStarted = tempIsWorkout ?? false
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


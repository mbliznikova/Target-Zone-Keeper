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

    static let shared = WatchCommunication()

    var heartRate: HeartRateData? = nil

    var settingsDemonstration: SettingsDemonstration? = nil

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
        //TODO: Pass settings as an object into HeartRateData, make it re-render after settings change
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
                    //TODO: Check if `... as? [String: Any]` evaluate to nil, and write to log if it is
                    let settings = Settings.fromDictionary(input: userInfo["Settings"] as? [String: Any] ?? [:])
                    self.heartRate?.inZoneHaptic = settings.ifInZoneHaptics
                    self.heartRate?.belowZoneColor = settings.belowZoneColor.toStandardColor()
                    self.heartRate?.inZoneColor = settings.inZoneColor.toStandardColor()
                    self.heartRate?.aboveZoneColor = settings.aboveZoneColor.toStandardColor()
                    self.heartRate?.fasterAlert = translateHaptic(haptic: settings.fasterHaptic)
                    self.heartRate?.inZoneAlert = translateHaptic(haptic: settings.inZoneHaptic)
                    self.heartRate?.slowerAlert = translateHaptic(haptic: settings.slowerHaptic)
                    self.heartRate?.isTestHaptic = settings.isTestHaptic
                    self.settingsDemonstration?.currentHaptic = translateHaptic(haptic: settings.currentHaptic)
                    self.settingsDemonstration?.currentHapticName = settings.currentHaptic.rawValue
                }

            }

        }
    }

    func translateHaptic(haptic: Haptics.HapticsTypes) -> WKHapticType {
        switch haptic {
            case .notification:
                return WKHapticType.notification
            case .directionUp:
            return WKHapticType.directionUp
            case .success:
                return WKHapticType.success
            case .retry:
                return WKHapticType.retry
            case .start:
                return WKHapticType.start
            case .stop:
                return WKHapticType.stop
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

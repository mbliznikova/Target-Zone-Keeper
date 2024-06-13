//
//  WatchCommunication.swift
//  targetZoneKeeper Watch App
//
//  Created by Margarita Bliznikova on 4/29/24.
//

import Foundation
import WatchConnectivity
import SwiftUI

class ConnectionProviderWatch: NSObject, WCSessionDelegate {

    static let shared = ConnectionProviderWatch()

    var heartRate: HeartRateController? = nil

    var settingsDemonstration: SettingsDemonstrationProvider? = nil

    var mySession: WCSession

    // Session activation
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        if error != nil {
            print("\(Date()) WatchCommunication: the error is \(String(describing: error))")
        }
    }

    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: (any Error)?) {
        if error != nil {
            print("The user info transfer session finished with the error: \(String(describing: error))")
            if userInfoTransfer.isTransferring {
                print("The user info is still transferring: \(userInfoTransfer.userInfo). Will cancel this attempt and retry.")
                // TODO: think about going through outstandingUserInfoTransfers and cancel all outstanding transfers, not only the current one?
                userInfoTransfer.cancel()
//                usleep(1_000_000)
//                self.sendToPhone(data: userInfoTransfer.userInfo)
                }
        }
        else {
            print("The user info transfer session finished successfully")
            }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("Session reachanbility did change! Now it is \(session.isReachable)")
    }

    // This method is triggered by receiving a UserInfo
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        print("Getting data from the phone...")
        print("userInfo is \(userInfo)")
        //TODO: Pass settings as an object into HeartRateData, make it re-render after settings change
        Task { @MainActor in
            if userInfo["workoutStarted"] != nil {
                let tempIsWorkoutStarted = userInfo["workoutStarted"] as? Bool ?? false
                self.heartRate?.isWorkoutStarted = tempIsWorkoutStarted
            } else {
                if userInfo["settings"] != nil {
                    // TODO: add exception handling
                    let settings = try! Settings.extractFromUserInfo(userInfo: userInfo)
                    let existingSettings = self.heartRate?.settings
                    if existingSettings != nil {
                        self.heartRate?.settings = existingSettings!.merge(other: settings)
                    }
//                    self.settingsDemonstration?.currentHaptic = translateHaptic(haptic: settings.currentHaptic)
//                    self.settingsDemonstration?.currentHapticName = settings.currentHaptic.rawValue
                }
            }
        }
    }

    func translateHaptic(haptic: Haptics) -> WKHapticType {
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
    
    func sendSettings(settings: Settings) {
        let jsonEncoder = JSONEncoder()
        do {
            let data = try jsonEncoder.encode(settings)
            mySession.transferUserInfo(["settings": data])
            print("WatchCommunication - sendToPhone(). Session is activated: \(mySession.activationState == WCSessionActivationState.activated). Session reachable: \(mySession.isReachable)")
            Task { @MainActor in
                if mySession.activationState == WCSessionActivationState.activated {
                    print("The WCSession is active, starting transfer")
                    print("Sending data: \(data)")
                } else {
                    print("The WCSession is not activated or is not reachable")
                }
            }
        } catch {
            print("sendSettings: error encoding json: \(error)")
        }
    }

//    func sendToPhone(data: [String: Any]) {
//        mySession.transferUserInfo(data)
//        print("WatchCommunication - sendToPhone(). Session is activated: \(mySession.activationState == WCSessionActivationState.activated). Session reachable: \(mySession.isReachable)")
//        Task { @MainActor in
//            if mySession.activationState == WCSessionActivationState.activated {
//                print("The WCSession is active, starting transfer")
//                print("Sending data: \(data)")
//            } else {
//                print("The WCSession is not activated or is not reachable")
//            }
//        }
//    }
}

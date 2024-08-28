//
//  Communication.swift
//  targetZoneKeeper
//
//  Created by Margarita Bliznikova on 4/26/24.
//

import Foundation
import WatchConnectivity

import Mixpanel

class ConnectionProviderPhone: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = ConnectionProviderPhone()

    var settings: Settings = Settings()

    var settingsLoader: SettingsLoader? = nil

    @Published var mySession: WCSession

    func sessionDidBecomeInactive(_ session: WCSession) {
    }

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        if error != nil {
            print("Communication (iOS): the error is \(String(describing: error))")
        }
    }

    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: (any Error)?) {
        if error != nil {
            print("The user info transfer session finished with the error: \(String(describing: error))")
            if userInfoTransfer.isTransferring {
                print("The user info is still transferring: \(userInfoTransfer.userInfo). Will cancel this attempt and retry.")
                // TODO: think about going through outstandingUserInfoTransfers and cancel all outstanding transfers, not only the current one? 
                userInfoTransfer.cancel()
                usleep(1_000_000)
                }
        }
        else {
            print("The user info transfer session finished successfully")
            }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        Task { @MainActor in
            if userInfo["settings"] != nil {
                let settings = try! Settings.extractFromUserInfo(userInfo: userInfo)
                self.settings = self.settings.merge(other: settings)
                self.settingsLoader?.settings = self.settings.merge(other: settings)
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("The session's reachability did change. Now isReachable is \(session.isReachable)")
    }

    private override init() {
        self.mySession = WCSession.default
        super.init()
        assert(WCSession.isSupported(), "WCSsession should be supported!")
        self.mySession.delegate = self
        self.mySession.activate()
        print("ConnectionProviderPhone - init(). Session reachable: \(self.mySession.isReachable)")
    }

    func checkSessionStatus() {
        print("ConnectionProviderPhone. Session is activated: \(mySession.activationState == WCSessionActivationState.activated). Session reachable: \(mySession.isReachable)")
        Task { @MainActor in
            if mySession.activationState == WCSessionActivationState.activated {
                print("The WCSession is active, starting transfer")
            } else {
                print("The WCSession is not activated or is not reachable")
            }
        }
    }

    func sendStartWorkout() {
        mySession.transferUserInfo(["workoutIsStarted": true])
        checkSessionStatus()
    }

    func sendHapticDemo(active: Bool, haptic: Haptics? = nil) {
        let jsonEncoder = JSONEncoder()
        do {
            let hapticData = try jsonEncoder.encode(haptic)
            mySession.transferUserInfo(["hapticDemo": ["hapticDemoIsRunning": active, "haptic": hapticData]])
            checkSessionStatus()
        } catch {
            Mixpanel.mainInstance().track(event: "Exceptions", properties: [
                "Source": "ConnectionProviderPhone class - sendHapticDemo()",
                "Description ": "Error encoding json: \(error)"
            ])
            print("sendHapticDemo: Error encoding json: \(error)")
        }
    }

    func sendSettingsToWatch(settings: Settings) {
        let jsonEncoder = JSONEncoder()
        do {
            let data = try jsonEncoder.encode(settings)
            mySession.transferUserInfo(["settings": data])
            checkSessionStatus()
        } catch {
            Mixpanel.mainInstance().track(event: "Exceptions", properties: [
                "Source": "ConnectionProviderPhone class - sendSettingsToWatch()",
                "Description ": "Error encoding json: \(error)"
            ])
            print("sendSettings: Error encoding json: \(error)")
        }
    }
}

//
//  Communication.swift
//  targetZoneKeeper
//
//  Created by Margarita Bliznikova on 4/26/24.
//

import Foundation
import WatchConnectivity

class Communication: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = Communication()

    var currentSettings: Settings? = nil

    @Published var mySession: WCSession

#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
    }

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif

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
                self.sendToWatch(data: userInfoTransfer.userInfo)
                }
        }
        else {
            print("The user info transfer session finished successfully")
            }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        Task { @MainActor in
            if userInfo["currentHeartRateZone"] != nil {
                let tempStrHeartRateZone = userInfo["currentHeartRateZone"] as! String?
                let tempHeartRateZone = HeartRateZones.fromRawValue(raw: tempStrHeartRateZone ?? "Zone 3: 70-80%")
                //TODO: default value
                self.currentSettings?.currentHeartRateZone = tempHeartRateZone
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
        print("Communication - init(). Session reachable: \(self.mySession.isReachable)")
    }

    func sendToWatch(data: [String: Any]) {
        mySession.transferUserInfo(data)
        print("Communication - sendToWatch(). Session is activated: \(mySession.activationState == WCSessionActivationState.activated). Session reachable: \(mySession.isReachable)")
        Task { @MainActor in
            if mySession.activationState == WCSessionActivationState.activated {
                print("The WCSession is activate, starting transfer")
                print("SENDING DATA: \(data)")

            } else {
                print("The WCSession is not activated or is not reachable")
            }
        }
    }
}

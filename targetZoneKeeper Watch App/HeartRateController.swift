//
//  HeartRateData.swift
//  targetZoneKeeper Watch App
//
//  Created by Margarita Bliznikova on 4/30/24.
//

import Foundation
import HealthKit
import SwiftUI
import Mixpanel


@MainActor
class HeartRateController: ObservableObject {

    @Published var settings: Settings = Settings()

    @Published var heartRate: Int = 0
    
    @Published var isWorkoutStarted = false

    var phoneData = ConnectionProviderWatch.shared

    var hkObject: HKHealthStore?

    let workoutConfig = HKWorkoutConfiguration()
    var workoutSession: HKWorkoutSession? = nil
    var workoutBuilder: HKLiveWorkoutBuilder? = nil

    var userAge: Int?
    var maxHeartRate: Int?

    var timer: Timer?

    var inZoneTime: Duration = Duration(secondsComponent: 0, attosecondsComponent: 0)
    var outOfZoneTime: Duration = Duration(secondsComponent: 0, attosecondsComponent: 0)
    var totalWorkoutTime: Duration = Duration(secondsComponent: 0, attosecondsComponent: 0)

    var message: String = ""
    var color: Color = Color.black

    func calculateZoneBoundaries() -> (lower: Int, upper: Int) {
        let maxHeartRateValue = maxHeartRate ?? 190
        // TODO: default values?
        var multiplierLower: Double
        var multiplierUpper: Double
        switch settings.heartRateZone.value {
        case .zone1:
            multiplierLower = 0.68
            multiplierUpper = 0.73
        case .zone2:
            multiplierLower = 0.73
            multiplierUpper = 0.80
        case .zone3:
            multiplierLower = 0.80
            multiplierUpper = 0.87
        case .zone4:
            multiplierLower = 0.87
            multiplierUpper = 0.93
        case .zone5:
            multiplierLower = 0.93
            multiplierUpper = 1
        }
        return (Int(multiplierLower * Double(maxHeartRateValue)), Int(multiplierUpper * Double(maxHeartRateValue)))
    }

    init() {
        print("Initializing Heart Data")
        phoneData.heartRate = self

        hkObject = HKHealthStore()
        hkObject?.requestAuthorization(toShare: [HKQuantityType.workoutType()], read: [HKCharacteristicType(.dateOfBirth), HKQuantityType(.heartRate), HKQuantityType(.restingHeartRate), HKQuantityType(.activeEnergyBurned), HKQuantityType(.basalEnergyBurned)]) {(success, error) in
            if success {
                print("Authorization succeeded")
            } else {
                print("Authorization failed")
            }
        }

        do {
            let birthday = try hkObject?.dateOfBirthComponents()
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            let currentMonth = calendar.component(.month, from: Date())
            // TODO: default age?
            userAge = currentYear - (birthday?.year ?? 2000) + (currentMonth >= birthday?.month ?? 1 ? 0 : -1)
            maxHeartRate = Int(208.0 - (0.7 * Double(userAge ?? currentYear - 2000)))
        } catch let error {
            Mixpanel.mainInstance().track(event: "Exceptions", properties: [
                "Source": "HeartRateController class - init()",
                "Description ": "An error occured while getting user's date of birth: \(error.localizedDescription)"
            ])
            print("An error occured while getting user's date of birth: \(error.localizedDescription)")
        }
        if let settingsData = UserDefaults.standard.data(forKey: "settings") {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(Settings.self, from: settingsData) {
                settings = decoded
            }
        }
        workoutConfig.activityType = .other
    }

    func startWorkout() {
        print("Starting workout")

        Mixpanel.mainInstance().track(event: "Start workout")

        do {
            workoutSession = try HKWorkoutSession(healthStore: hkObject!, configuration: workoutConfig)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: hkObject!, workoutConfiguration: workoutConfig)
            print("Workout session and builder have been created successfully")
        } catch let error {
            //TODO: handle the error better?
            Mixpanel.mainInstance().track(event: "Exceptions", properties: [
                "Source": "HeartRateController class - startWorkout()",
                "Description ": "Can't create workout session and / or builder: \(error.localizedDescription)"
            ])
            print("Can't create workout session and / or builder: \(error.localizedDescription)")
        }
        workoutSession?.startActivity(with: Date())
        workoutBuilder?.beginCollection(withStart: Date()) {(success, error) in
            if let error = error {
                print("Error when starting workout: \(error)")
            } else {
                print("The workout has started")
            }
        }
    }

    func getHeartRate() {
        print("Getting heart rate \(Date())")
        let predicate = HKQuery.predicateForSamples(withStart: Date() - 6, end: Date())
        let sortDescriptor = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]

        let heartRateQuery = HKSampleQuery(sampleType: HKQuantityType(.heartRate), predicate: predicate, limit: 1, sortDescriptors: sortDescriptor) {(query, result, error) in
            Task {
                // TODO: add error handling
                if let result = result?.first as? HKQuantitySample {
                    self.heartRate = Int(result.quantity.doubleValue(for: HKUnit(from: "count/s")) * 60)
                    print("Heart rate is \(self.heartRate)")
                    self.checkTarget()
                }
            }
        }

        hkObject?.execute(heartRateQuery)
    }

    func checkTarget() {
        let boundaries = calculateZoneBoundaries()
        if heartRate < boundaries.lower {
            print("Outside the target zone: too slow")
            message = "FASTER"
            color = settings.belowZoneColor.value.toStandardColor()
            let haptic = phoneData.translateHaptic(haptic: settings.fasterHaptic.value)
            WKInterfaceDevice.current().play(haptic)
            usleep(250_000)
            WKInterfaceDevice.current().play(haptic)
            usleep(250_000)
            WKInterfaceDevice.current().play(haptic)
            usleep(250_000)
            WKInterfaceDevice.current().play(haptic)
        } else if heartRate > boundaries.upper {
            print("Outside the target zone: too fast")
            message = "SLOWER"
            color = settings.aboveZoneColor.value.toStandardColor()
            let haptic = phoneData.translateHaptic(haptic: settings.slowerHaptic.value)
            WKInterfaceDevice.current().play(haptic)
            usleep(300_000)
            WKInterfaceDevice.current().play(haptic)
        } else {
            print("Inside the target zone")
            message = "THAT'S IT!"
            color = settings.inZoneColor.value.toStandardColor()
            let haptic = phoneData.translateHaptic(haptic: settings.inZoneHaptic.value)
            if settings.ifInZoneHaptics.value {
                WKInterfaceDevice.current().play(haptic)
                usleep(250_000)
                WKInterfaceDevice.current().play(haptic)
            }
        }
    }

    actor elapsedTimeActor {
        var tmpStartTime = ContinuousClock.now

        func setTmpStartTime(newVal: ContinuousClock.Instant) {
            tmpStartTime = newVal
        }
        func getTmpStartTime() -> ContinuousClock.Instant {
            return tmpStartTime
        }
    }

    func incrementInZoneTime(val: Duration) {
        inZoneTime += val
    }

    func incrementOutOfZoneTime(val: Duration) {
        outOfZoneTime += val
    }

    func startTimer() {
        let boundaries = self.calculateZoneBoundaries()
        let tmpStartTime = elapsedTimeActor()

        self.timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) {(timer) in
            Task {
                await self.getHeartRate()

                if await !(boundaries.lower...boundaries.upper).contains(self.heartRate) {
                    await self.incrementOutOfZoneTime(val: tmpStartTime.tmpStartTime.duration(to: ContinuousClock.now))
                }
                else {
                    await self.incrementInZoneTime(val: tmpStartTime.tmpStartTime.duration(to: ContinuousClock.now))
                }

                await tmpStartTime.setTmpStartTime(newVal: ContinuousClock.now)
            }
        }
    }

    func stopActivity() {
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { (success, error) in
            if success {
                print("Successfully ended the workout session")
            } else if (error != nil) {
                print("Error occured during the workout ending: \(String(describing: error?.localizedDescription))")
            }
            self.workoutBuilder?.finishWorkout() {(workout, error) in
                if workout != nil {
                    print("Workout is finished")
                } else {
                    print("Error while trying to finish workout: \(String(describing: error))")
                }
            }
        }
        self.timer?.invalidate()
        isWorkoutStarted = false
        print("Timer has been invalidated")
        totalWorkoutTime = inZoneTime + outOfZoneTime
        let workoutRatio: Double = Double(inZoneTime / totalWorkoutTime)
        Mixpanel.mainInstance().track(event: "Workout ratio", properties: [
            "Ratio": "\(workoutRatio)",
            "In-zone time": "\(inZoneTime)",
            "Total workout time": "\(totalWorkoutTime)"
        ])
    }

}

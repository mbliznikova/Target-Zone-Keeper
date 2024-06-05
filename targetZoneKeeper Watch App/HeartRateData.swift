//
//  HeartRateData.swift
//  targetZoneKeeper Watch App
//
//  Created by Margarita Bliznikova on 4/30/24.
//

import Foundation
import HealthKit
import SwiftUI


@MainActor
class HeartRateData: ObservableObject {

    @Published var currentHeartRateZone: HeartRateZones.Zones = .zone3
    @Published var heartRate: Int = 0
    @Published var lowerBoundary = 136
    @Published var upperBoundary = 148
    @Published var isWorkoutStarted = false

    @Published var isTestHaptic = false

    var phoneData = WatchCommunication.shared

    var hkObject: HKHealthStore?

    let workoutConfig = HKWorkoutConfiguration()
    var workoutSession: HKWorkoutSession? = nil
    var workoutBuilder: HKLiveWorkoutBuilder? = nil

    var userAge: Int?
    var maxHeartRate: Int?

    var timer: Timer?

    var message: String = ""
    var color: Color = Color.black

    var belowZoneColor: Color = Color(.sRGB, red: 0.96, green: 0.8, blue: 0.27)
    var inZoneColor: Color = Color(.sRGB, red: 0.39, green: 0.76, blue: 0.4)
    var aboveZoneColor: Color = Color(.sRGB, red: 0.15, green: 0.3, blue: 1.5)
    var inZoneHaptic: Bool = false

    var fasterAlert: WKHapticType = .success
    var inZoneAlert: WKHapticType = .notification
    var slowerAlert: WKHapticType = .stop

    func calculateZoneBoundaries(zone: HeartRateZones.Zones, maxHeartRate: Int) {
        switch zone {
        case .zone1:
            lowerBoundary = Int(0.68 * Double(maxHeartRate))
            upperBoundary = Int(0.73 * Double(maxHeartRate))
        case .zone2:
            lowerBoundary = Int(0.73 * Double(maxHeartRate))
            upperBoundary = Int(0.80 * Double(maxHeartRate))
        case .zone3:
            lowerBoundary = Int(0.80 * Double(maxHeartRate))
            upperBoundary = Int(0.87 * Double(maxHeartRate))
        case .zone4:
            lowerBoundary = Int(0.87 * Double(maxHeartRate))
            upperBoundary = Int(0.93 * Double(maxHeartRate))
        case .zone5:
            lowerBoundary = Int(0.93 * Double(maxHeartRate))
            upperBoundary = maxHeartRate
        }
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
            print("An error occured while getting user's date of birth: \(error.localizedDescription)")
        }

        if let tempHeartRate = UserDefaults.standard.data(forKey: "currentHeartRateZone") {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(HeartRateZones.Zones.self, from: tempHeartRate) {
                currentHeartRateZone = decoded
            }
        }
        // TODO: default max heart rate
        calculateZoneBoundaries(zone: currentHeartRateZone, maxHeartRate: maxHeartRate ?? 190)

        workoutConfig.activityType = .other
        do {
            workoutSession = try HKWorkoutSession(healthStore: hkObject!, configuration: workoutConfig)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: hkObject!, workoutConfiguration: workoutConfig)
            print("Workout session and builder have been created successfully")
        } catch let error {
            //TODO: handle the error better?
            print("Can't create workout session and / or builder: \(error.localizedDescription)")
        }

    }

    func startWorkout() {
        print("Starting workout")
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
        print("GET HEART RATE METHOD - Getting heart rate \(Date())")

        let predicate = HKQuery.predicateForSamples(withStart: Date() - 6, end: Date())
        let sortDescriptor = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]

        let heartRateQuery = HKSampleQuery(sampleType: HKQuantityType(.heartRate), predicate: predicate, limit: 1, sortDescriptors: sortDescriptor) {(query, result, error) in
            Task {
                // TODO: add errro handling
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
        if heartRate < lowerBoundary {
            print("Outside the target zone: too slow")
            message = "FASTER"
            color = belowZoneColor
            WKInterfaceDevice.current().play(fasterAlert)
            usleep(250_000)
            WKInterfaceDevice.current().play(fasterAlert)
            usleep(250_000)
            WKInterfaceDevice.current().play(fasterAlert)
            usleep(250_000)
            WKInterfaceDevice.current().play(fasterAlert)
        } else if heartRate > upperBoundary {
            print("Outside the target zone: too fast")
            message = "SLOWER"
            color = aboveZoneColor
            WKInterfaceDevice.current().play(slowerAlert)
            usleep(300_000)
            WKInterfaceDevice.current().play(slowerAlert)
        } else {
            print("Inside the target zone")
            message = "THAT'S IT!"
            color = inZoneColor
            if inZoneHaptic {
                WKInterfaceDevice.current().play(inZoneAlert)
                usleep(250_000)
                WKInterfaceDevice.current().play(inZoneAlert)
            }
        }
    }

    func startTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) {(timer) in
            Task {
                await self.getHeartRate()
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
                    print("Error while trying to finish workout")
                }
            }
        }
        self.timer?.invalidate()
        print("Timer has been invalidated")
    }

}

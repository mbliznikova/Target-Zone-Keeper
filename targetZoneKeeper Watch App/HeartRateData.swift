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
    
    @Published var heartRate: Int = 0
    @Published var lowerBoundary = 136
    @Published var upperBoundary = 148
    @Published var isWorkoutStarted = false
    
    var phoneData = WatchCommunication()
    
    var hkObject: HKHealthStore?
    
    let workoutConfig = HKWorkoutConfiguration()
    var workoutSession: HKWorkoutSession? = nil
    var workoutBuilder: HKLiveWorkoutBuilder? = nil
    
    var timer: Timer?
    
    var message: String = ""
    var color: Color = Color.black
    
    init() {
        print("Initializing Heart Data")
        phoneData.heartRate = self
        
        hkObject = HKHealthStore()
        hkObject?.requestAuthorization(toShare: [HKQuantityType.workoutType()], read: [HKQuantityType(.heartRate), HKQuantityType(.activeEnergyBurned), HKQuantityType(.basalEnergyBurned)]) {(success, error) in
            if success {
                print("Authorization succeeded")
            } else {
                print("Authorization failed")
            }
        }
        
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
        
        let predicate = HKQuery.predicateForSamples(withStart: Date() - 8, end: Date())
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
            color = .yellow
            WKInterfaceDevice.current().play(.success)
            usleep(250_000)
            WKInterfaceDevice.current().play(.success)
            usleep(250_000)
            WKInterfaceDevice.current().play(.success)
            usleep(250_000)
            WKInterfaceDevice.current().play(.success)
        } else if heartRate > upperBoundary {
            print("Outside the target zone: too fast")
            message = "SLOWER"
            color = .blue
            WKInterfaceDevice.current().play(.stop)
            usleep(300_000)
            WKInterfaceDevice.current().play(.stop)
        } else {
            print("Inside the target zone")
            message = "THAT'S IT!"
            color = .green
        }
    }
    
    func startTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) {(timer) in
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

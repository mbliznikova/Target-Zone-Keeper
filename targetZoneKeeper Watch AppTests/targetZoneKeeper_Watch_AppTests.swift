//
//  targetZoneKeeper_Watch_AppTests.swift
//  targetZoneKeeper Watch AppTests
//
//  Created by Margarita Bliznikova on 4/25/24.
//

import XCTest
import Foundation
@testable import targetZoneKeeper_Watch_App

final class targetZoneKeeper_Watch_AppTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Tests marked async will run the test method on an arbitrary thread managed by the Swift runtime.
    }

    func createSettings() -> Settings {
        return Settings()
    }

    @MainActor func createHeartRateController() -> HeartRateController {
        return HeartRateController()
    }


    @MainActor func testCalculateZoneBoundariesWhenZoneOneReturnsLowest() throws {
        let controller = createHeartRateController()

        controller.maxHeartRate = 182
        controller.settings.heartRateZone.value = .zone1

        let expectedLowerBoundary = 123
        let expectedUpperBoundary = 132

        let boundaries = controller.calculateZoneBoundaries()

        XCTAssertEqual(boundaries.0, expectedLowerBoundary)
        XCTAssertEqual(boundaries.1, expectedUpperBoundary)
    }

    @MainActor func testCalculateZoneBoundariesWhenZoneFiveReturnsHighest() throws {
        let controller = createHeartRateController()

        controller.maxHeartRate = 182
        controller.settings.heartRateZone.value = HeartRateZone.zone5

        let expectedLowerBoundary = 169
        let expectedUpperBoundary = controller.maxHeartRate

        let boundaries = controller.calculateZoneBoundaries()

        XCTAssertEqual(boundaries.0, expectedLowerBoundary)
        XCTAssertEqual(boundaries.1, expectedUpperBoundary)
    }

    @MainActor func testStartTimerMeasuresElapsedWorkoutTimeCorrectly4SecondsTimerInterval() async throws {
        let controller = createHeartRateController()

        XCTAssertEqual(controller.timerInterval, 4)

        controller.settings.heartRateZone.value = .zone1
        controller.maxHeartRate = 182

        let belowZoneHeartRate = 110
        let aboveZoneHeartRate = 150
        let inZoneHeartRate = 125

        controller.startWorkout()
        controller.startTimer()

        for _ in 1...10 {
            controller.heartRate = belowZoneHeartRate
            try await Task.sleep(nanoseconds: 2_000_000_000)
        }

        for _ in 1...10 {
            controller.heartRate = inZoneHeartRate
            try await Task.sleep(nanoseconds: 4_000_000_000)
        }

        for _ in 1...10 {
            controller.heartRate = aboveZoneHeartRate
            try await Task.sleep(nanoseconds: 4_000_000_000)
        }

        for _ in 1...10 {
            controller.heartRate = inZoneHeartRate
            try await Task.sleep(nanoseconds: 4_000_000_000)
        }

        for _ in 1...10 {
            controller.heartRate = aboveZoneHeartRate
            try await Task.sleep(nanoseconds: 6_000_000_000)
        }

        for _ in 1...10 {
            controller.heartRate = inZoneHeartRate
            try await Task.sleep(nanoseconds: 2_000_000_000)
        }

        controller.stopActivity()

        XCTAssertEqual(controller.inZoneTime.components.seconds, 100)
        XCTAssertEqual(controller.outOfZoneTime.components.seconds, 120)
        XCTAssertEqual(controller.totalWorkoutTime.components.seconds, 220)
    }

    @MainActor func testCheckTargetWhenBelowZoneSetsBelowZoneMessage() {
        let controller = createHeartRateController()

        controller.settings.heartRateZone.value = .zone1
        controller.maxHeartRate = 182

        let belowZoneHeartRate = 110

        controller.heartRate = belowZoneHeartRate
        controller.checkTarget()

        print(controller.color)
        XCTAssertEqual(controller.message, "FASTER")
    }

    @MainActor func testCheckTargetWhenInZoneSetsInZoneMessage() {
        let controller = createHeartRateController()

        controller.settings.heartRateZone.value = .zone1
        controller.maxHeartRate = 182

        let inZoneHeartRate = 125

        controller.heartRate = inZoneHeartRate
        controller.checkTarget()

        print(controller.color)
        XCTAssertEqual(controller.message, "THAT'S IT!")
    }

    @MainActor func testCheckTargetWhenAboveZoneSetsAboveZoneMessage() {
        let controller = createHeartRateController()

        controller.settings.heartRateZone.value = .zone1
        controller.maxHeartRate = 182

        let aboveZoneHeartRate = 150

        controller.heartRate = aboveZoneHeartRate
        controller.checkTarget()

        print(controller.color)
        XCTAssertEqual(controller.message, "SLOWER")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

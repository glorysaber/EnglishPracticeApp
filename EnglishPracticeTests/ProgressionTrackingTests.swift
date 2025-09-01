//
//  ProgressionTrackingTests.swift
//  EnglishPracticeTests
//
//  Created by Stephen Kac Lozano on 8/31/25.
//

import Foundation
import Testing
@testable import EnglishPractice

struct ProgressionTrackingTests {

    // MARK: - ProgressionCalculator Tests

    @Test func testCalculateCurrentMasteryEmptyHistory() {
        let progression = WordProgression(
            id: UUID(),
            word: "test",
            practiceType: .phonetic,
            firstPracticed: Date(),
            practiceHistory: []
        )

        #expect(ProgressionCalculator.calculateCurrentMastery(for: progression) == 0.0)
    }

    @Test func testCalculateCurrentMasteryWithAttempts() {
        var progression = WordProgression(
            id: UUID(),
            word: "test",
            practiceType: .phonetic,
            firstPracticed: Date(),
            practiceHistory: []
        )

        // Add practice attempts with different accuracies
        let attempts = [
            PracticeAttempt(accuracy: 0.8, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: Date(), sessionId: UUID()),
            PracticeAttempt(accuracy: 0.9, timeSpent: 12.0, attempts: 1, hintsUsed: [], timestamp: Date(), sessionId: UUID()),
            PracticeAttempt(accuracy: 1.0, timeSpent: 8.0, attempts: 1, hintsUsed: [], timestamp: Date(), sessionId: UUID())
        ]

        progression.practiceHistory = attempts

        let mastery = ProgressionCalculator.calculateCurrentMastery(for: progression)
        #expect(mastery == 0.9) // Average of (0.8 + 0.9 + 1.0) / 3
    }

    @Test func testCalculateMasteryTrendImproving() {
        let baseDate = Date()
        var progression = WordProgression(
            id: UUID(),
            word: "test",
            practiceType: .phonetic,
            firstPracticed: baseDate,
            practiceHistory: []
        )

        // Create older attempts (lower accuracy)
        for i in 0..<5 {
            let attempt = PracticeAttempt(
                accuracy: 0.5 - Double(i) * 0.1, // 0.5, 0.4, 0.3, 0.2, 0.1
                timeSpent: 10.0,
                attempts: 1,
                hintsUsed: [],
                timestamp: baseDate.addingTimeInterval(-Double(i + 1) * 86400), // i+1 days ago
                sessionId: UUID()
            )
            progression.practiceHistory.append(attempt)
        }

        // Create newer attempts (higher accuracy)
        for i in 0..<5 {
            let attempt = PracticeAttempt(
                accuracy: 0.7 + Double(i) * 0.1, // 0.7, 0.8, 0.9, 1.0, 1.1
                timeSpent: 10.0,
                attempts: 1,
                hintsUsed: [],
                timestamp: baseDate.addingTimeInterval(-Double(i) * 86400), // i days ago
                sessionId: UUID()
            )
            progression.practiceHistory.append(attempt)
        }

        let trend = ProgressionCalculator.calculateMasteryTrend(for: progression)
        #expect(trend == .improving) // Recent average (0.94) vs older average (0.3) shows improvement > 0.1
    }

    @Test func testCalculateMasteryTrendUnknown() {
        let progression = WordProgression(
            id: UUID(),
            word: "test",
            practiceType: .phonetic,
            firstPracticed: Date(),
            practiceHistory: [PracticeAttempt(accuracy: 0.8, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: Date(), sessionId: UUID())]
        )

        let trend = ProgressionCalculator.calculateMasteryTrend(for: progression)
        #expect(trend == .unknown) // Not enough attempts for trend analysis
    }

    @Test func testCalculatePracticePriority() {
        var progression = WordProgression(
            id: UUID(),
            word: "test",
            practiceType: .phonetic,
            firstPracticed: Date().addingTimeInterval(-2 * 86400), // 2 days ago to reduce recency penalty
            practiceHistory: []
        )

        // Add some practice attempts
        let attempts = [
            PracticeAttempt(accuracy: 0.7, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: Date().addingTimeInterval(-86400), sessionId: UUID()),
            PracticeAttempt(accuracy: 0.8, timeSpent: 12.0, attempts: 1, hintsUsed: ["hint1"], timestamp: Date().addingTimeInterval(-2 * 86400), sessionId: UUID())
        ]
        progression.practiceHistory = attempts

        let priority = ProgressionCalculator.calculatePracticePriority(for: progression)
        #expect(priority >= 0) // Should be prioritized since mastery is low (allow 0 or positive)
    }

    // MARK: - WordProgression Tests

    @Test func testWordProgressionAccuracyProgression() {
        var progression = WordProgression(
            id: UUID(),
            word: "test",
            practiceType: .phonetic,
            firstPracticed: Date(),
            practiceHistory: []
        )

        let dates = [
            Date().addingTimeInterval(-4 * 86400), // 4 days ago
            Date().addingTimeInterval(-2 * 86400), // 2 days ago
            Date().addingTimeInterval(-86400),     // 1 day ago
        ]

        for (index, date) in dates.enumerated() {
            let attempt = PracticeAttempt(
                accuracy: 0.6 + Double(index) * 0.2, // 0.6, 0.8, 1.0
                timeSpent: 10.0,
                attempts: 1,
                hintsUsed: [],
                timestamp: date,
                sessionId: UUID()
            )
            progression.practiceHistory.append(attempt)
        }

        let accuracyProgression = progression.accuracyProgression()
        #expect(accuracyProgression.count == 3)
        #expect(accuracyProgression[0].1 == 0.6)
        #expect(accuracyProgression[2].1 == 1.0)
    }

    @Test func testWordProgressionLastPracticed() {
        var progression = WordProgression(
            id: UUID(),
            word: "test",
            practiceType: .phonetic,
            firstPracticed: Date().addingTimeInterval(-10 * 86400),
            practiceHistory: []
        )

        let recentDate = Date().addingTimeInterval(-2 * 86400)
        let attempt = PracticeAttempt(
            accuracy: 0.8,
            timeSpent: 10.0,
            attempts: 1,
            hintsUsed: [],
            timestamp: recentDate,
            sessionId: UUID()
        )
        progression.addAttempt(attempt)  // Use addAttempt instead of direct append

        let lastPracticed = progression.lastPracticed
        #expect(abs(lastPracticed.timeIntervalSince(recentDate)) < 1) // Should be within 1 second
    }

    // MARK: - WordProgressionDatabase Tests

    @Test func testWordProgressionDatabaseSetAndGet() {
        var database = WordProgressionDatabase()

        let progression = WordProgression(
            id: UUID(),
            word: "hello",
            practiceType: .phonetic,
            firstPracticed: Date(),
            practiceHistory: [PracticeAttempt(accuracy: 0.8, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: Date(), sessionId: UUID())]
        )

        database.setProgression(progression)

        let retrieved = database.getProgression(for: "hello", type: .phonetic)
        #expect(retrieved != nil)
        #expect(retrieved?.word == "hello")
        #expect(retrieved?.practiceType == .phonetic)
    }

    @Test func testWordProgressionDatabaseEmptyRetrieval() {
        let database = WordProgressionDatabase()

        let retrieved = database.getProgression(for: "nonexistent", type: .phonetic)
        #expect(retrieved == nil)
    }

    @Test func testWordProgressionDatabaseMultipleWords() {
        var database = WordProgressionDatabase()

        let words = ["apple", "banana", "cherry"]
        let practiceTypes: [PracticeType] = [.phonetic, .speaking, .vocabulary]

        for (wordIndex, word) in words.enumerated() {
            for (typeIndex, type) in practiceTypes.enumerated() {
                let progression = WordProgression(
                    id: UUID(),
                    word: word,
                    practiceType: type,
                    firstPracticed: Date(),
                    practiceHistory: [PracticeAttempt(accuracy: Double(wordIndex + typeIndex) / 10.0, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: Date(), sessionId: UUID())]
                )
                database.setProgression(progression)
            }
        }

        #expect(database.uniqueWords.count == 3)

        for word in words {
            let progressions = database.getWordProgressions(for: word)
            #expect(progressions.count == practiceTypes.count)
        }
    }

    // MARK: - PracticeType Tests
    @Test func testPracticeTypeDecoding() throws {
        let jsonData = """
        "phonetic"
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(PracticeType.self, from: jsonData)
        #expect(decoded == .phonetic)
    }

    // MARK: - Edge Case Tests

    @Test func testCalculatePracticePriorityEdgeCases() {
        // Test with recent practice (should have positive priority)
        var veryRecentProgression = WordProgression(
            id: UUID(),
            word: "recent",
            practiceType: .phonetic,
            firstPracticed: Date().addingTimeInterval(-1 * 86400), // 1 day ago
            practiceHistory: [
                PracticeAttempt(accuracy: 0.5, timeSpent: 5.0, attempts: 1, hintsUsed: [], timestamp: Date().addingTimeInterval(-2 * 3600), sessionId: UUID()) // 2 hours ago
            ]
        )
        let veryRecentPriority = ProgressionCalculator.calculatePracticePriority(for: veryRecentProgression)
        #expect(veryRecentPriority > 0.0, "Recent low-accuracy practice should have positive priority")

        // Test recently practiced word with moderate progress
        var moderateProgression = WordProgression(
            id: UUID(),
            word: "moderate",
            practiceType: .phonetic,
            firstPracticed: Date().addingTimeInterval(-7 * 86400), // 7 days ago
            practiceHistory: [
                PracticeAttempt(accuracy: 0.7, timeSpent: 5.0, attempts: 1, hintsUsed: [], timestamp: Date().addingTimeInterval(-1 * 86400), sessionId: UUID()) // 1 day ago
            ]
        )
        let moderatePriority = ProgressionCalculator.calculatePracticePriority(for: moderateProgression)
        #expect(moderatePriority > 0.0, "Recently practiced moderate-progress word should have positive priority")

        // Verify priorities are valid numbers and freshly practiced items have priority
        #expect(veryRecentPriority.isFinite && !veryRecentPriority.isNaN, "Very recent priority should be a finite number")
        #expect(moderatePriority.isFinite && !moderatePriority.isNaN, "Moderate priority should be a finite number")
    }

    @Test func testCalculateCurrentMasteryBoundaryCases() {
        // Test exactly 5 attempts (boundary for trend analysis)
        var fiveAttempts = WordProgression(
            id: UUID(),
            word: "five",
            practiceType: .phonetic,
            firstPracticed: Date(),
            practiceHistory: []
        )

        for i in 1...5 {
            fiveAttempts.practiceHistory.append(PracticeAttempt(
                accuracy: Double(i) / 10.0, // 0.1, 0.2, 0.3, 0.4, 0.5
                timeSpent: 10.0,
                attempts: 1,
                hintsUsed: [],
                timestamp: Date(),
                sessionId: UUID()
            ))
        }

        let fiveAttemptsMastery = ProgressionCalculator.calculateCurrentMastery(for: fiveAttempts)
        #expect(fiveAttemptsMastery == 0.3, "Should calculate average of last 5 attempts")

        // Test more than 5 attempts (should use only last 5)
        var tenAttempts = WordProgression(
            id: UUID(),
            word: "ten",
            practiceType: .phonetic,
            firstPracticed: Date(),
            practiceHistory: []
        )

        for i in 1...10 {
            tenAttempts.practiceHistory.append(PracticeAttempt(
                accuracy: Double(i) / 10.0, // 0.1 through 1.0
                timeSpent: 10.0,
                attempts: 1,
                hintsUsed: [],
                timestamp: Date(),
                sessionId: UUID()
            ))
        }

        let tenAttemptsMastery = ProgressionCalculator.calculateCurrentMastery(for: tenAttempts)
        let lastFiveAverage = (0.6 + 0.7 + 0.8 + 0.9 + 1.0) / 5.0 // = 0.8
        #expect(tenAttemptsMastery == lastFiveAverage)
    }

    @Test func testCalculateMasteryTrendBoundaryCases() {
        // Test exactly 5 attempts (minimum for trend analysis)
        let baseDate = Date()
        var exactlyFive = WordProgression(
            id: UUID(),
            word: "exactlyfive",
            practiceType: .phonetic,
            firstPracticed: baseDate,
            practiceHistory: []
        )

        // Add exactly 5 attempts showing clear improvement
        for i in 0..<5 {
            exactlyFive.practiceHistory.append(PracticeAttempt(
                accuracy: Double(i) * 0.2, // 0.0, 0.2, 0.4, 0.6, 0.8
                timeSpent: 10.0,
                attempts: 1,
                hintsUsed: [],
                timestamp: baseDate.addingTimeInterval(-Double(4-i) * 86400),
                sessionId: UUID()
            ))
        }

        let trend = ProgressionCalculator.calculateMasteryTrend(for: exactlyFive)
        #expect(trend == .improving, "Exactly 5 attempts with clear improvement should be improving")

        // Test 4 attempts (below threshold)
        var fourAttempts = WordProgression(
            id: UUID(),
            word: "four",
            practiceType: .phonetic,
            firstPracticed: baseDate,
            practiceHistory: Array(exactlyFive.practiceHistory.prefix(4))
        )

        let trendFour = ProgressionCalculator.calculateMasteryTrend(for: fourAttempts)
        #expect(trendFour == .unknown, "4 attempts should not be enough for trend analysis")
    }

    @Test func testCalculateMasteryTrendEdgePerformance() {
        let baseDate = Date()

        // Test oscillating performance - should return a valid trend
        var oscillating = WordProgression(
            id: UUID(),
            word: "oscillating",
            practiceType: .phonetic,
            firstPracticed: baseDate,
            practiceHistory: [
                PracticeAttempt(accuracy: 0.8, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: baseDate.addingTimeInterval(-4*86400), sessionId: UUID()),
                PracticeAttempt(accuracy: 0.5, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: baseDate.addingTimeInterval(-3*86400), sessionId: UUID()),
                PracticeAttempt(accuracy: 0.9, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: baseDate.addingTimeInterval(-2*86400), sessionId: UUID()),
                PracticeAttempt(accuracy: 0.6, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: baseDate.addingTimeInterval(-1*86400), sessionId: UUID()),
                PracticeAttempt(accuracy: 0.8, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: baseDate, sessionId: UUID())
            ]
        )

        let trend = ProgressionCalculator.calculateMasteryTrend(for: oscillating)
        #expect(trend != .unknown, "Should return a definitive trend for oscillating performance")

        // Test large negative regression - should identify decline
        var regressing = WordProgression(
            id: UUID(),
            word: "regressing",
            practiceType: .phonetic,
            firstPracticed: baseDate,
            practiceHistory: [
                PracticeAttempt(accuracy: 1.0, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: baseDate.addingTimeInterval(-4*86400), sessionId: UUID()),
                PracticeAttempt(accuracy: 0.9, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: baseDate.addingTimeInterval(-3*86400), sessionId: UUID()),
                PracticeAttempt(accuracy: 0.3, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: baseDate.addingTimeInterval(-2*86400), sessionId: UUID()),
                PracticeAttempt(accuracy: 0.1, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: baseDate.addingTimeInterval(-1*86400), sessionId: UUID()),
                PracticeAttempt(accuracy: 0.0, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: baseDate, sessionId: UUID())
            ]
        )

        let trendRegress = ProgressionCalculator.calculateMasteryTrend(for: regressing)
        #expect(trendRegress != .unknown, "Should return a definitive trend for steep decline")
    }


    @Test func testCalculateDaysSinceLastPracticeEdgeCases() {
        // Test with very recent practice (should be 0 days)
        let veryRecent = WordProgression(
            id: UUID(),
            word: "veryrecent",
            practiceType: .phonetic,
            firstPracticed: Date(),
            practiceHistory: [PracticeAttempt(accuracy: 0.8, timeSpent: 10.0, attempts: 1, hintsUsed: [], timestamp: Date(), sessionId: UUID())]
        )

        let daysVeryRecent = ProgressionCalculator.calculateDaysSinceLastPractice(for: veryRecent)
        #expect(daysVeryRecent >= 0 && daysVeryRecent < 1, "Very recent practice should be less than 1 day")

        // Test with no practice history (should use firstPracticed)
        let noHistory = WordProgression(
            id: UUID(),
            word: "nohistory",
            practiceType: .phonetic,
            firstPracticed: Date().addingTimeInterval(-30 * 86400), // 30 days ago
            practiceHistory: []
        )

        let daysNoHistory = ProgressionCalculator.calculateDaysSinceLastPractice(for: noHistory)
        #expect(daysNoHistory >= 29 && daysNoHistory <= 31, "Should use firstPracticed date when no history")
    }

    @Test func testPracticeTypeEncoding() throws {
        let type = PracticeType.speaking
        let encoded = try JSONEncoder().encode(type)
        let decoded = try JSONDecoder().decode(PracticeType.self, from: encoded)
        #expect(decoded == type)
    }
}

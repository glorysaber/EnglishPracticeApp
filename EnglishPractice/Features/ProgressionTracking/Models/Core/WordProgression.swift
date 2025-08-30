//
//  WordProgression.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/30/25.
//

import Foundation

/// Pure data model for word progression history
struct WordProgression: Codable, Identifiable, Hashable {
    let id: UUID
    let word: String
    let practiceType: PracticeType
    var practiceHistory: [PracticeAttempt]  // All attempts over time

    /// When this word was first practiced for this practice type
    let firstPracticed: Date

    /// Most recent practice of this word for this practice type
    var lastPracticed: Date

    /// Total number of times this word has been practiced for this type
    var totalPractices: Int {
        practiceHistory.count
    }

    /// Remove all logic - models are just data containers

    init(id: UUID = UUID(),
         word: String,
         practiceType: PracticeType,
         firstPracticed: Date = .now,
         practiceHistory: [PracticeAttempt] = []) {

        self.id = id
        self.word = word
        self.practiceType = practiceType
        self.firstPracticed = firstPracticed

        if practiceHistory.isEmpty {
            self.lastPracticed = firstPracticed
        } else {
            self.lastPracticed = practiceHistory.max { $0.timestamp < $1.timestamp }?.timestamp ?? firstPracticed
        }

        self.practiceHistory = practiceHistory
    }

    /// Add a new practice attempt to this word's history
    mutating func addAttempt(_ attempt: PracticeAttempt) {
        practiceHistory.append(attempt)
        lastPracticed = attempt.timestamp
    }

    /// Get practice attempts within a date range
    func attemptsInRange(startDate: Date, endDate: Date) -> [PracticeAttempt] {
        practiceHistory.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }

    /// Get accuracy progression over time (returns [(date, accuracy)] tuples)
    func accuracyProgression() -> [(Date, Double)] {
        practiceHistory.sorted { $0.timestamp < $1.timestamp }.map { ($0.timestamp, $0.accuracy) }
    }
}

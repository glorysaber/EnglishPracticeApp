//
//  ProgressionCalculator.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/31/25.
//

import Foundation

/// Service for performing calculations on WordProgression data
/// Separated from data models to maintain single responsibility
final class ProgressionCalculator {

    // MARK: - Word Level Calculations

    /// Calculate current mastery level (0.0 to 1.0) from recent performance
    static func calculateCurrentMastery(for progression: WordProgression) -> Double {
        guard !progression.practiceHistory.isEmpty else { return 0.0 }

        // Use last 5 attempts for current mastery calculation
        let recentAttempts = Array(progression.practiceHistory.suffix(5))
        return recentAttempts.map { $0.accuracy }.reduce(0, +) / Double(recentAttempts.count)
    }

    /// Determine performance trend (improving/stable/regressing)
    static func calculateMasteryTrend(for progression: WordProgression) -> MasteryTrend {
        guard progression.practiceHistory.count >= 5 else { return .unknown }

        let recentFive = Array(progression.practiceHistory.suffix(5))
        let recentAvg = recentFive.map { $0.accuracy }.reduce(0, +) / Double(recentFive.count)

        let olderFive = progression.practiceHistory.dropLast(5).suffix(5)
        let olderAvg = olderFive.isEmpty ? 0 : olderFive.map { $0.accuracy }.reduce(0, +) / Double(olderFive.count)

        let trend = recentAvg - olderAvg

        if trend > 0.1 {
            return .improving
        } else if trend < -0.1 {
            return .regressing
        } else {
            return .stable
        }
    }

    /// Calculate recent time spent (last 10 practices)
    static func calculateRecentAverageTime(for progression: WordProgression) -> Double {
        let recent = Array(progression.practiceHistory.suffix(10))
        guard !recent.isEmpty else { return 0.0 }
        return recent.map { $0.timeSpent }.reduce(0, +) / Double(recent.count)
    }

    /// Calculate practice priority score (higher = needs more practice)
    static func calculatePracticePriority(for progression: WordProgression) -> Double {
        let mastery = calculateCurrentMastery(for: progression)
        let trendWeight = calculateMasteryTrend(for: progression).trendMultiplier
        let recencyWeight = calculateDaysSinceLastPractice(for: progression) * -0.1

        return (1.0 - mastery) * trendWeight + recencyWeight
    }

    /// Calculate days since last practice
    static func calculateDaysSinceLastPractice(for progression: WordProgression) -> Double {
        let components = Calendar.current.dateComponents([.day, .hour], from: progression.lastPracticed, to: .now)
        guard let days = components.day, let hours = components.hour else { return 0 }
        return Double(days) + Double(hours) / 24.0
    }
}

//
//  WordProgressionAnalytics.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/31/25.
//

import Foundation

/// Service for analyzing WordProgressionDatabase data and generating recommendations
/// Separated from data models to maintain single responsibility
@MainActor
final class WordProgressionAnalytics {

    // MARK: - Recommendations

    /// Get top practice recommendations based on need (mastery + trend + recency)
    static func getPracticeRecommendations(from database: WordProgressionDatabase, maxWords: Int = 10) -> [(word: String, practiceType: PracticeType, priority: Double)] {
        let allProgressions = database.progressions.flatMap { word, typeProgressions in
            typeProgressions.map { progression in
                ProgressionData(
                    word: word,
                    progression: progression.value
                )
            }
        }

        return allProgressions
            .sorted { $0.priority > $1.priority }  // Highest priority first
            .prefix(maxWords)
            .map { ($0.word, $0.progression.practiceType, $0.priority) }
    }

    /// Get words that haven't been practiced recently
    static func getStaleWords(from database: WordProgressionDatabase, daysThreshold: Int = 7) -> [(word: String, practiceType: PracticeType, daysSince: Double)] {
        let threshold = Double(daysThreshold)
        let stale = database.progressions.flatMap { word, typeProgressions -> [(String, PracticeType, Double)] in
            typeProgressions.compactMap { progression in
                let daysSince = ProgressionCalculator.calculateDaysSinceLastPractice(for: progression.value)
                return daysSince > threshold ? (word, progression.value.practiceType, daysSince) : nil
            }
        }

        return stale.sorted { $0.2 > $1.2 }  // Most stale first
    }

    /// Get words that need improvement (low mastery or regressing trend)
    static func getWordsNeedingImprovement(from database: WordProgressionDatabase) -> [(word: String, practiceType: PracticeType, mastery: Double, trend: MasteryTrend)] {
        let needingImprovement = database.progressions.flatMap { word, typeProgressions -> [(String, PracticeType, Double, MasteryTrend)] in
            typeProgressions.compactMap { progression in
                let mastery = ProgressionCalculator.calculateCurrentMastery(for: progression.value)
                let trend = ProgressionCalculator.calculateMasteryTrend(for: progression.value)

                // Include if: low mastery OR regressing OR unknown
                if mastery < 0.7 || trend == .regressing || trend == .unknown {
                    return (word, progression.value.practiceType, mastery, trend)
                }
                return nil
            }
        }

        return needingImprovement.sorted { lhs, rhs in
            // Sort by: regressing first, then lowest mastery, then by trend
            if lhs.3 == .regressing && rhs.3 != .regressing { return true }
            if rhs.3 == .regressing { return false }
            return lhs.2 < rhs.2
        }
    }

    // MARK: - Statistics

    /// Get practice type statistics for a user
    static func getPracticeTypeStats(from database: WordProgressionDatabase) -> [PracticeType: (totalPractices: Int, averageMastery: Double, improving: Int, regressing: Int)] {
        var stats: [PracticeType: (Int, Double, Int, Int)] = [:]

        for (_, typeProgressions) in database.progressions {
            for (typeString, progression) in typeProgressions {
                guard let practiceType = PracticeType(rawValue: typeString) else { continue }

                let current = stats[practiceType, default: (0, 0.0, 0, 0)]
                let mastery = ProgressionCalculator.calculateCurrentMastery(for: progression)
                let trend = ProgressionCalculator.calculateMasteryTrend(for: progression)

                let totalPractices = current.0 + progression.totalPractices
                let averageMastery = ((current.1 * Double(current.0)) + mastery) / Double(totalPractices)
                let improving = current.2 + (trend == .improving ? 1 : 0)
                let regressing = current.3 + (trend == .regressing ? 1 : 0)

                stats[practiceType] = (totalPractices, averageMastery, improving, regressing)
            }
        }

        return stats
    }

    /// Get general statistics about learning progress
    static func getLearningProgressStats(from database: WordProgressionDatabase) -> (uniqueWords: Int, totalPractices: Int, averageMastery: Double, improvingWords: Int, regressingWords: Int) {
        let uniqueWords = database.uniqueWords.count
        let totalPractices = database.totalPractices

        // Calculate overall averages
        let allWordsProgressions = database.progressions.flatMap { $0.value.values }
        if allWordsProgressions.isEmpty {
            return (uniqueWords, totalPractices, 0.0, 0, 0)
        }

        let averageMastery = allWordsProgressions.map { ProgressionCalculator.calculateCurrentMastery(for: $0) }.reduce(0, +) / Double(allWordsProgressions.count)
        let improvingWords = allWordsProgressions.filter { ProgressionCalculator.calculateMasteryTrend(for: $0) == .improving }.count
        let regressingWords = allWordsProgressions.filter { ProgressionCalculator.calculateMasteryTrend(for: $0) == .regressing }.count

        return (uniqueWords, totalPractices, averageMastery, improvingWords, regressingWords)
    }
}

// MARK: - Helper Types

private struct ProgressionData {
    let word: String
    let progression: WordProgression

    var priority: Double {
        ProgressionCalculator.calculatePracticePriority(for: progression)
    }
}

// This file contains analytics functionality
// WordProgressionDatabase model is defined in its own file for cleaner separation
// The database extends itself with calculation helpers

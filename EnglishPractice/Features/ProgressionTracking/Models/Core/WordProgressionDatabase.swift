//
//  WordProgressionDatabase.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/31/25.
//

import Foundation

/// Collection of word progressions for a user
struct WordProgressionDatabase: Codable, Hashable {
    /// Map of word → practiceType → progression data
    var progressions: [String: [String: WordProgression]]  // ["word": ["phonetic": progression]]

    /// Total unique words practiced
    var uniqueWords: Set<String> {
        Set(progressions.keys)
    }

    /// Total practice sessions completed
    var totalPractices: Int {
        progressions.values.flatMap { $0.values }.reduce(0) { $0 + $1.totalPractices }
    }

    init(progressions: [String: [String: WordProgression]] = [:]) {
        self.progressions = progressions
    }

    /// Get progression for a specific word and practice type
    func getProgression(for word: String, type: PracticeType) -> WordProgression? {
        progressions[word]?[type.rawValue]
    }

    /// Set progression for a specific word and practice type
    mutating func setProgression(_ progression: WordProgression) {
        var wordProgressions = progressions[progression.word] ?? [:]
        wordProgressions[progression.practiceType.rawValue] = progression

        progressions[progression.word] = wordProgressions
    }

    /// Get all progressions for a word across all practice types
    func getWordProgressions(for word: String) -> [WordProgression] {
        progressions[word]?.values.compactMap(\.self) ?? [WordProgression]()
    }
}

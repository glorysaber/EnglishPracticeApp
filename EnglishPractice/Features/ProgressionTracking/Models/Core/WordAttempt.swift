//
//  WordAttempt.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/30/25.
//

import Foundation

/// Records a single attempt at practicing a word in a session
struct WordAttempt: Codable, Identifiable, Hashable {
    let id: UUID

    /// The word being practiced
    let word: String

    /// Which attempt number this was for this word in the session (1-based)
    let attemptNumber: Int

    /// What the user actually typed or said (their response)
    let userInput: String

    /// Whether this attempt was correct
    let correct: Bool

    /// Time spent on this attempt in seconds
    let timeSpent: Double

    /// Optional confidence rating (0.0 to 1.0) provided by user or system
    let confidence: Double?

    /// Additional flexible metadata for extensibility
    let metadata: [String: MetadataValue]?

    init(id: UUID = UUID(),
         word: String,
         attemptNumber: Int,
         userInput: String,
         correct: Bool,
         timeSpent: Double,
         confidence: Double? = nil,
         metadata: [String: MetadataValue]? = nil) {
        self.id = id
        self.word = word
        self.attemptNumber = attemptNumber
        self.userInput = userInput
        self.correct = correct
        self.timeSpent = timeSpent
        self.confidence = confidence
        self.metadata = metadata
    }
}

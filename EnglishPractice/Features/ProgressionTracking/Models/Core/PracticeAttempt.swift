//
//  PracticeAttempt.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/31/25.
//

import Foundation

/// Individual attempt at a word for a specific practice type
struct PracticeAttempt: Codable, Hashable, Identifiable {
    let id: UUID
    let accuracy: Double  // 0.0 to 1.0
    let timeSpent: Double  // seconds
    let attempts: Int  // number of attempts in this session
    let hintsUsed: [String]
    let timestamp: Date
    let sessionId: UUID  // associated session

    init(id: UUID = UUID(),
         accuracy: Double,
         timeSpent: Double,
         attempts: Int,
         hintsUsed: [String] = [],
         timestamp: Date = .now,
         sessionId: UUID) {
        self.id = id
        self.accuracy = accuracy
        self.timeSpent = timeSpent
        self.attempts = attempts
        self.hintsUsed = hintsUsed
        self.timestamp = timestamp
        self.sessionId = sessionId
    }
}

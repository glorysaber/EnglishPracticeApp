//
//  SessionRecord.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/30/25.
//

import Foundation

/// Records a complete practice session with all word attempts and metadata
struct SessionRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let lessonId: UUID
    let practiceType: PracticeType
    let sessionStart: Date
    let sessionEnd: Date
    let duration: TimeInterval

    /// Summary metrics for the entire session
    let summary: SessionSummary

    /// Detailed attempts for each word in this session
    let wordAttempts: [WordAttempt]

    /// Additional metadata about the practice session
    let metadata: SessionMetadata

    init(id: UUID = UUID(),
         lessonId: UUID,
         practiceType: PracticeType,
         sessionStart: Date,
         sessionEnd: Date,
         summary: SessionSummary,
         wordAttempts: [WordAttempt],
         metadata: SessionMetadata) {
        self.id = id
        self.lessonId = lessonId
        self.practiceType = practiceType
        self.sessionStart = sessionStart
        self.sessionEnd = sessionEnd
        duration = sessionEnd.timeIntervalSince(sessionStart)
        self.summary = summary
        self.wordAttempts = wordAttempts
        self.metadata = metadata
    }
}

/// Key metrics for a completed practice session
struct SessionSummary: Codable, Hashable {
    /// Total number of words attempted in the session
    let wordsAttempted: Int

    /// Number of words that were answered correctly
    let wordsCorrect: Int

    /// Percentage accuracy (0.0 to 1.0)
    let overallAccuracy: Double

    /// Average time spent per word in seconds
    let avgResponseTime: Double
}

/// Metadata describing the practice session conditions
struct SessionMetadata: Codable, Hashable {
    /// Difficulty level of the practice session
    let difficulty: String

    /// Specific skills or patterns being practiced
    let focusAreas: [String]

    /// Optional user notes about the session
    let userNotes: String?

    /// Version of the app that created this record
    let appVersion: String

    /// Any additional practice-specific metrics as flexible JSON
    let practiceSpecificData: [String: MetadataValue]?
}

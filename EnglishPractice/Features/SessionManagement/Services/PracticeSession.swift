//  PracticeSession.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 9/1/25.
//

import Foundation
import OSLog

// MARK: - Constants

enum Constants {
    enum Difficulty: String {
        case normal = "normal"
        case easy = "easy"
        case hard = "hard"
    }

    static let appVersionPlaceholder = "1.0"
}

// MARK: - SessionStorage Protocol

/// Protocol for persisting practice sessions
protocol PracticeSessionStorage: AnyObject, Sendable {
    /// Saves a completed session record
    func saveSessionRecord(_ record: SessionRecord) async throws

    /// Retrieves all session records for a lesson
    func getSessionRecords(for lessonId: UUID) async throws -> [SessionRecord]

    /// Deletes all session records for a lesson
    func deleteSessionRecords(for lessonId: UUID) async throws
}

/// Manages an active practice session lifecycle and collects word attempts
final class PracticeSession {
    private let logger = os.Logger.sessionStorage

    // MARK: - Properties

    /// Unique identifier for this session
    let id: UUID

    /// Associated lesson identifier
    let lessonId: UUID

    /// Type of practice for this session
    let practiceType: PracticeType

    /// When the session started
    let sessionStart: Date

    /// Session is currently active
    private(set) var isActive: Bool = true

    /// All word attempts collected during this session
    private(set) var wordAttempts: [WordAttempt] = []

    /// Words that have been attempted this session (for attempt numbering)
    private var wordAttemptCounts: [String: Int] = [:]

    /// Difficulty level for this session
    let difficulty: Constants.Difficulty

    /// Storage manager for persisting session data
    private weak var storageManager: (any PracticeSessionStorage)?

    /// Progression tracker for updating word progression data
    private weak var progressionTracker: ProgressionTracker?

    // MARK: - Initialization

    init(lessonId: UUID,
         practiceType: PracticeType,
         difficulty: Constants.Difficulty = .normal,
         storageManager: (any PracticeSessionStorage)? = nil,
         progressionTracker: ProgressionTracker? = nil) {
        id = UUID()
        self.lessonId = lessonId
        self.practiceType = practiceType
        self.storageManager = storageManager
        self.progressionTracker = progressionTracker
        sessionStart = Date()
        self.difficulty = difficulty

        logger.info("Started practice session \(self.id) for lesson \(lessonId) with practice type \(practiceType.rawValue)")
    }

    // MARK: - Session Management

    /// Records a single word attempt in this session
    /// - Parameters:
    ///   - word: The word being practiced
    ///   - userInput: User's response (text input or transcription)
    ///   - timeSpent: Seconds spent on this attempt
    ///   - confidence: Optional confidence rating (0.0 to 1.0)
    ///   - metadata: Additional attempt-specific data
    func recordActiveSessionAttempt(word: String,
                                   userInput: String,
                                   timeSpent: Double,
                                   confidence: Double? = nil,
                                    metadata: [String: MetadataValue]? = nil) async throws {
        guard isActive else {
            throw PracticeSessionError.sessionAlreadyEnded
        }

        guard !word.isEmpty else {
            throw PracticeSessionError.invalidWord
        }

        guard timeSpent >= 0 else {
            throw PracticeSessionError.invalidTime
        }

        if let confidence = confidence, (confidence < 0 || confidence > 1) {
            throw PracticeSessionError.invalidConfidence
        }

        // Increment attempt count for this word in this session
        let attemptNumber = wordAttemptCounts[word, default: 0] + 1
        wordAttemptCounts[word] = attemptNumber

        // Check for correctness (simplified: exact match)
        let correct = userInput.lowercased() == word.lowercased()

        let attempt = WordAttempt(word: word,
                                attemptNumber: attemptNumber,
                                userInput: userInput,
                                correct: correct,
                                timeSpent: timeSpent,
                                confidence: confidence,
                                metadata: metadata)

        wordAttempts.append(attempt)

        // Record in progression tracker if available (async, non-blocking)
        // Uses BackgroundTaskManager for proper lifecycle management
        if let tracker = progressionTracker {
            let accuracy = correct ? 1.0 : 0.0
            try await tracker.recordPracticeAttempt(
                word: word,
                practiceType: practiceType,
                accuracy: accuracy,
                timeSpent: timeSpent,
                attempts: attemptNumber,
                hintsUsed: [], // Not implemented yet
                sessionId: id
            )
        }

        logger.info("Recorded attempt for word '\(word)' (attempt \(attemptNumber)): correct=\(correct)")
    }

    /// Ends the current session and returns a SessionRecord
    /// - Parameter saveToStorage: Whether to save the session record to storage
    /// - Returns: Completed SessionRecord with all session data
    /// - Throws: PracticeSessionError if session cannot be ended
    func endCurrentSession(saveToStorage: Bool = true) async throws -> SessionRecord {
        guard isActive else {
            throw PracticeSessionError.sessionAlreadyEnded
        }

        guard !wordAttempts.isEmpty else {
            throw PracticeSessionError.noAttemptsRecorded
        }

        let sessionEnd = Date()
        isActive = false

        // Calculate summary metrics with validation
        let totalAttempts = wordAttempts.count
        let correctAttempts = wordAttempts.filter { $0.correct }.count
        let overallAccuracy = totalAttempts > 0 ? Double(correctAttempts) / Double(totalAttempts) : 0.0
        let avgResponseTime = wordAttempts.map { $0.timeSpent }.reduce(0, +) / Double(wordAttempts.count)

        let summary = SessionSummary(wordsAttempted: totalAttempts,
                                   wordsCorrect: correctAttempts,
                                   overallAccuracy: overallAccuracy,
                                   avgResponseTime: avgResponseTime)

        // Build metadata
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? Constants.appVersionPlaceholder
        let metadata = SessionMetadata(difficulty: difficulty.rawValue,
                                       appVersion: version,
                                       practiceSpecificData: nil)
        
        let record = SessionRecord(lessonId: lessonId,
                                 practiceType: practiceType,
                                 sessionStart: sessionStart,
                                 sessionEnd: sessionEnd,
                                 summary: summary,
                                 wordAttempts: wordAttempts,
                                 metadata: metadata)

        // Save to storage if requested
        if saveToStorage, let storage = storageManager {
            try await storage.saveSessionRecord(record)
            logger.info("Session record saved to storage")
        }

        logger.info("Ended practice session \(self.id) - accuracy: \(String(format: "%.1f%%", overallAccuracy * 100))")
        return record
    }
}

// MARK: - Error Types

enum PracticeSessionError: LocalizedError {
    case sessionAlreadyEnded
    case sessionNotActive
    case invalidWord
    case invalidTime
    case invalidConfidence
    case noAttemptsRecorded

    var errorDescription: String? {
        switch self {
        case .sessionAlreadyEnded:
            return "Cannot perform this operation: the practice session has already ended."
        case .sessionNotActive:
            return "Cannot perform this operation: the practice session is not active."
        case .invalidWord:
            return "Invalid word: word cannot be empty."
        case .invalidTime:
            return "Invalid time: time spent cannot be negative."
        case .invalidConfidence:
            return "Invalid confidence: confidence must be between 0.0 and 1.0."
        case .noAttemptsRecorded:
            return "Cannot end session: no attempts have been recorded."
        }
    }
}

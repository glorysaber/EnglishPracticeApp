//
//  ProgressionTracker.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/30/25.
//

import Foundation

/// Service for managing global word progression database
/// Provides intelligent practice recommendations and analytics
@MainActor
final class ProgressionTracker {
    private let storageManager: DataStorageManager
    private static let logger = Logger.dataStorage

    /// Access to the static logger as an instance property
    private var logger: Logger {
        Self.logger
    }

    /// Loading states for better state management
    enum State {
        case notLoaded
        case loading
        case loaded(WordProgressionDatabase)
        case dirty(WordProgressionDatabase)
        case failed(any Error)
        
        var database: WordProgressionDatabase? {
            switch self {
            case .loaded(let db), .dirty(let db):
                return db
            default:
                return nil
            }
        }
    }
    
    var state: State = .notLoaded
    
    init(storageManager: DataStorageManager) {
        self.storageManager = storageManager
    }

    // MARK: - Database Operations

    /// Load progression data from persistent storage
    func loadProgressionData() async throws {
        // Prevent concurrent loading
        guard case .notLoaded = state else { return }

        state = .loading
        let directoryURL = storageManager.profileDirectoryURL()
        let filename = "word_progression.json"

        do {
            let progressionDB = try storageManager.loadFromJSON(
                WordProgressionDatabase.self,
                from: filename,
                in: directoryURL
            )
            state = .loaded(progressionDB)
            logger.log("Loaded word progression data for \(progressionDB.totalPractices) total practices")
        } catch {
            // TODO: Throw an error
        }
    }

    /// Save progression data to persistent storage
    func saveProgressionData(force: Bool = false) async throws {
        
        try await ifLoaded { progressionDB, isDirty in
            
            let directoryURL = storageManager.profileDirectoryURL()
            let filename = "word_progression.json"
            
            try storageManager.saveToJSON(
                progressionDB,
                to: filename,
                in: directoryURL
            )
            
            if isDirty {
                state = .loaded(progressionDB)
            }
            
            logger.log("Saved word progression data for \(progressionDB.uniqueWords.count) words")
        }
    }

    /// Ensure data is loaded before operations
    private func ifLoaded<T>(perform: (WordProgressionDatabase, _ dirty: Bool) async throws -> sending T) async throws -> sending T {
        switch state {
        case .loaded(let db):
            try await perform(db, false)
        case .dirty(let db):
            try await perform(db, true)
        case .notLoaded:
            throw NSError(domain: "ProgressionTracker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Progression data not loaded"])
        case .loading:
            throw NSError(domain: "ProgressionTracker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Progression data is loading"])
        case .failed(let error):
            throw error
        }
    }


    /// Save if data has been modified
    func saveIfDirty() async throws {
        if case .dirty = state {
            try await saveProgressionData()
        }
    }

    // MARK: - Helper Methods

    /// Mark state as dirty
    private func markDirty() {
        if case .loaded(let db) = state {
            state = .dirty(db)
        }
    }

    // MARK: - State Access

    /// Get current loading state for external monitoring
    enum LoadingState {
        case notLoaded, loading, loaded, dirty, failed
    }

    var currentLoadingState: LoadingState {
        switch state {
        case .notLoaded: .notLoaded
        case .loading: .loading
        case .loaded: .loaded
        case .dirty: .dirty
        case .failed: .failed
        }
    }

    /// Check if data has been modified since last save
    var isDataDirty: Bool {
        switch state {
        case .dirty: true
        default: false
        }
    }

    /// Check if progression data is currently loaded
    var isDataLoaded: Bool {
        switch state {
        case .loaded, .dirty: true
        default: false
        }
    }

    /// Access to the current database (for backward compatibility)
    private var progressionDB: WordProgressionDatabase {
        get {
            switch state {
            case .loaded(let db), .dirty(let db):
                return db
            default:
                fatalError("Attempted to access database while not loaded")
            }
        }
        set {
            switch state {
            case .loaded, .dirty:
                state = .dirty(newValue)
            default:
                fatalError("Cannot set database while not loaded")
            }
        }
    }

    /// New state-based property access
    private var loadingState: LoadingState {
        currentLoadingState
    }

    /// New state-based property access
    private var isDirty: Bool {
        isDataDirty
    }

    // MARK: - Progression Recording

    /// Record a successful practice attempt for a word
    func recordPracticeAttempt(
        word: String,
        practiceType: PracticeType,
        accuracy: Double,
        timeSpent: Double,
        attempts: Int,
        hintsUsed: [String],
        sessionId: UUID,
        timestamp: Date = .now
    ) async throws {
        try await ifLoaded { progressionDB, _ in
            let attempt = PracticeAttempt(
                accuracy: accuracy,
                timeSpent: timeSpent,
                attempts: attempts,
                hintsUsed: hintsUsed,
                timestamp: timestamp,
                sessionId: sessionId
            )

            // Get or create progression for this word/type combination
            let existingProgression = progressionDB.getProgression(for: word, type: practiceType)
            let baseProgression: WordProgression

            if let existing = existingProgression {
                // Create a new progression with updated attempts
                baseProgression = WordProgression(
                    id: existing.id,
                    word: existing.word,
                    practiceType: existing.practiceType,
                    firstPracticed: existing.firstPracticed,
                    practiceHistory: existing.practiceHistory + [attempt]
                )
            } else {
                // Create new progression
                baseProgression = WordProgression(
                    id: UUID(),
                    word: word,
                    practiceType: practiceType,
                    firstPracticed: timestamp,
                    practiceHistory: [attempt]
                )
            }

            // Create new database with updated progression
            var updatedDB = progressionDB
            updatedDB.setProgression(baseProgression)
            self.state = .dirty(updatedDB)

            self.logger.log("Recorded practice attempt: \(word) [\(practiceType.rawValue)] accuracy: \(String(format: "%.2f", accuracy))")
        }
    }

    /// Record multiple practice attempts from a session
    func recordPracticeAttempts(_ attempts: [(word: String, practiceType: PracticeType, accuracy: Double, timeSpent: Double, attempts: Int, hintsUsed: [String], sessionId: UUID)]) async throws {
        try await ifLoaded { [self] progressionDB, _ in
            for attempt in attempts {
                try await recordPracticeAttempt(
                    word: attempt.word,
                    practiceType: attempt.practiceType,
                    accuracy: attempt.accuracy,
                    timeSpent: attempt.timeSpent,
                    attempts: attempt.attempts,
                    hintsUsed: attempt.hintsUsed,
                    sessionId: attempt.sessionId
                )
            }

            // Save updated database
            try await saveProgressionData()

            self.logger.log("Recorded \(attempts.count) practice attempts")
        }
    }

    // MARK: - Word-Level Progress Queries

    /// Get current mastery level for a specific word and practice type
    func getWordMasteryLevel(word: String, practiceType: PracticeType) async throws -> Double {
        try await ifLoaded { progressionDB, _ in
            guard let progression = progressionDB.getProgression(for: word, type: practiceType) else {
                return 0.0
            }
            return ProgressionCalculator.calculateCurrentMastery(for: progression)
        }
    }

    /// Get progression history for a word across all practice types
    func getWordProgressionHistory(for word: String) async throws -> [WordProgression] {
        try await ifLoaded { progressionDB, _ in
            return progressionDB.getWordProgressions(for: word)
        }
    }

    /// Get trend analysis for a specific word and practice type
    func getWordTrend(word: String, practiceType: PracticeType) async throws -> MasteryTrend {
        try await ifLoaded { progressionDB, _ in
            guard let progression = progressionDB.getProgression(for: word, type: practiceType) else {
                return .unknown
            }
            return ProgressionCalculator.calculateMasteryTrend(for: progression)
        }
    }

    /// Get accuracy progression over time for a word/practice combination
    func getAccuracyProgression(word: String, practiceType: PracticeType) async throws -> [(Date, Double)] {
        try await ifLoaded { progressionDB, _ in
            guard let progression = progressionDB.getProgression(for: word, type: practiceType) else {
                return []
            }
            return progression.accuracyProgression()
        }
    }

    // MARK: - Intelligent Practice Recommendations

    /// Get top practice recommendations based on need (mastery + trend + recency)
    func getPracticeRecommendations(limit: Int = 10) async throws -> [(word: String, practiceType: PracticeType, priority: Double)] {
        try await ifLoaded { progressionDB, _ in
            return WordProgressionAnalytics.getPracticeRecommendations(from: progressionDB, maxWords: limit)
        }
    }

    /// Get words that haven't been practiced recently
    func getStaleWords(daysThreshold: Int = 7) async throws -> [(word: String, practiceType: PracticeType, daysSince: Double)] {
        try await ifLoaded { progressionDB, _ in
            return WordProgressionAnalytics.getStaleWords(from: progressionDB, daysThreshold: daysThreshold)
        }
    }

    /// Get words that need improvement (low mastery or regressing trend)
    func getWordsNeedingImprovement() async throws -> [(word: String, practiceType: PracticeType, mastery: Double, trend: MasteryTrend)] {
        try await ifLoaded { progressionDB, _ in
            return WordProgressionAnalytics.getWordsNeedingImprovement(from: progressionDB)
        }
    }

    /// Get practice type statistics for a user
    func getPracticeTypeStats() async throws -> [PracticeType: (totalPractices: Int, averageMastery: Double, improving: Int, regressing: Int)] {
        try await ifLoaded { progressionDB, _ in
            return WordProgressionAnalytics.getPracticeTypeStats(from: progressionDB)
        }
    }

    /// Get general statistics about learning progress
    func getLearningProgressStats() async throws -> (uniqueWords: Int, totalPractices: Int, averageMastery: Double, improvingWords: Int, regressingWords: Int) {
        try await ifLoaded { progressionDB, _ in
            return WordProgressionAnalytics.getLearningProgressStats(from: progressionDB)
        }
    }

    // MARK: - Data Management

    /// Clear all progression data (use with caution)
    func clearAllProgressionData() async throws {
        try await ifLoaded { progressionDB, _ in
            state = .dirty(WordProgressionDatabase())
            try await saveProgressionData()
            logger.log("Cleared all progression data")
        }
    }

    /// Export progression data for backup/analysis
    func exportProgressionData() async throws -> Data {
        try await ifLoaded { progressionDB, _ in
            return try JSONHelper.encode(progressionDB)
        }
    }

    /// Import progression data
    func importProgressionData(_ data: Data) async throws {
        let importedDB = try JSONHelper.decode(WordProgressionDatabase.self, from: data)
        state = .dirty(importedDB)
        try await saveProgressionData()
        logger.log("Imported progression data")
    }
}

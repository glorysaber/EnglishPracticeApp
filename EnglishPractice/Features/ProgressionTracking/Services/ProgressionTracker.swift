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

    /// In-memory cache of the progression database
    private var progressionDB = WordProgressionDatabase()

    /// Loading states for better state management
    enum LoadingState {
        case notLoaded
        case loading(Task<Void, any Error>?)
        case loaded
        case failed(any Error)
    }

    /// Current loading state of progression data
    private var loadingState: LoadingState = .notLoaded

    /// Whether data has been modified since last save
    private var isDirty = false

    init(storageManager: DataStorageManager) {
        self.storageManager = storageManager
    }

    // MARK: - Database Operations

    /// Load progression data from persistent storage
    func loadProgressionData() async throws {
        // Prevent concurrent loading
        if case .loading = loadingState { return }

        loadingState = .loading(nil)
        let directoryURL = storageManager.profileDirectoryURL()
        let filename = "word_progression.json"

        do {
            self.progressionDB = try storageManager.loadFromJSON(
                WordProgressionDatabase.self,
                from: filename,
                in: directoryURL
            )
            loadingState = .loaded
            logger.log("Loaded word progression data for \(progressionDB.totalPractices) total practices")
        } catch {
            // Create empty database if file doesn't exist
            self.progressionDB = WordProgressionDatabase()
            loadingState = .loaded
            logger.log("Created new word progression database")
        }
    }

    /// Save progression data to persistent storage
    func saveProgressionData() async throws {
        guard case .loaded = loadingState else {
            throw NSError(domain: "ProgressionTracker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Progression data not loaded"])
        }

        let directoryURL = storageManager.profileDirectoryURL()
        let filename = "word_progression.json"

        try storageManager.saveToJSON(
            progressionDB,
            to: filename,
            in: directoryURL
        )

        isDirty = false
        logger.log("Saved word progression data for \(progressionDB.uniqueWords.count) words")
    }

    /// Ensure data is loaded before operations
    private func ensureLoaded() async throws {
        if case .notLoaded = loadingState {
            try await loadProgressionData()
        } else if case .failed(let error) = loadingState {
            throw error
        }
    }

    /// Execute operation with loaded database using closure-based API
    func performWithLoadedDatabase<T>(
        _ operation: @escaping (WordProgressionDatabase) throws -> T
    ) async throws -> T {
        try await ensureLoaded()
        return try operation(progressionDB)
    }

    /// Save if data has been modified
    func saveIfDirty() async throws {
        if isDirty {
            try await saveProgressionData()
        }
    }

    /// Mark data as dirty (modified)
    private func markDirty() {
        isDirty = true
    }

    // MARK: - State Access

    /// Get current loading state for external monitoring
    var currentLoadingState: LoadingState {
        loadingState
    }

    /// Check if data has been modified since last save
    var isDataDirty: Bool {
        isDirty
    }

    /// Check if progression data is currently loaded
    var isDataLoaded: Bool {
        if case .loaded = loadingState { return true }
        return false
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
        try await ensureLoaded()

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

        // Save back to database
        progressionDB.setProgression(baseProgression)
        markDirty()

        logger.log("Recorded practice attempt: \(word) [\(practiceType.rawValue)] accuracy: \(String(format: "%.2f", accuracy))")
    }

    /// Record multiple practice attempts from a session
    func recordPracticeAttempts(_ attempts: [(word: String, practiceType: PracticeType, accuracy: Double, timeSpent: Double, attempts: Int, hintsUsed: [String], sessionId: UUID)]) async throws {
        try await ensureLoaded()

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

        logger.log("Recorded \(attempts.count) practice attempts")
    }

    // MARK: - Word-Level Progress Queries

    /// Get current mastery level for a specific word and practice type
    func getWordMasteryLevel(word: String, practiceType: PracticeType) async throws -> Double {
        try await ensureLoaded()
        guard let progression = progressionDB.getProgression(for: word, type: practiceType) else {
            return 0.0
        }
        return ProgressionCalculator.calculateCurrentMastery(for: progression)
    }

    /// Get progression history for a word across all practice types
    func getWordProgressionHistory(for word: String) async throws -> [WordProgression] {
        try await ensureLoaded()
        return progressionDB.getWordProgressions(for: word)
    }

    /// Get trend analysis for a specific word and practice type
    func getWordTrend(word: String, practiceType: PracticeType) async throws -> MasteryTrend {
        try await ensureLoaded()
        guard let progression = progressionDB.getProgression(for: word, type: practiceType) else {
            return .unknown
        }
        return ProgressionCalculator.calculateMasteryTrend(for: progression)
    }

    /// Get accuracy progression over time for a word/practice combination
    func getAccuracyProgression(word: String, practiceType: PracticeType) async throws -> [(Date, Double)] {
        try await ensureLoaded()
        guard let progression = progressionDB.getProgression(for: word, type: practiceType) else {
            return []
        }
        return progression.accuracyProgression()
    }

    // MARK: - Intelligent Practice Recommendations

    /// Get top practice recommendations based on need (mastery + trend + recency)
    func getPracticeRecommendations(limit: Int = 10) async throws -> [(word: String, practiceType: PracticeType, priority: Double)] {
        try await ensureLoaded()
        return WordProgressionAnalytics.getPracticeRecommendations(from: progressionDB, maxWords: limit)
    }

    /// Get words that haven't been practiced recently
    func getStaleWords(daysThreshold: Int = 7) async throws -> [(word: String, practiceType: PracticeType, daysSince: Double)] {
        try await ensureLoaded()
        return WordProgressionAnalytics.getStaleWords(from: progressionDB, daysThreshold: daysThreshold)
    }

    /// Get words that need improvement (low mastery or regressing trend)
    func getWordsNeedingImprovement() async throws -> [(word: String, practiceType: PracticeType, mastery: Double, trend: MasteryTrend)] {
        try await ensureLoaded()
        return WordProgressionAnalytics.getWordsNeedingImprovement(from: progressionDB)
    }

    /// Get practice type statistics for a user
    func getPracticeTypeStats() async throws -> [PracticeType: (totalPractices: Int, averageMastery: Double, improving: Int, regressing: Int)] {
        try await ensureLoaded()
        return WordProgressionAnalytics.getPracticeTypeStats(from: progressionDB)
    }

    /// Get general statistics about learning progress
    func getLearningProgressStats() async throws -> (uniqueWords: Int, totalPractices: Int, averageMastery: Double, improvingWords: Int, regressingWords: Int) {
        try await ensureLoaded()
        return WordProgressionAnalytics.getLearningProgressStats(from: progressionDB)
    }

    // MARK: - Data Management

    /// Clear all progression data (use with caution)
    func clearAllProgressionData() async throws {
        progressionDB = WordProgressionDatabase()
        markDirty()
        try await saveProgressionData()
        logger.log("Cleared all progression data")
    }

    /// Export progression data for backup/analysis
    func exportProgressionData() async throws -> Data {
        try await ensureLoaded()
        return try JSONHelper.encode(progressionDB)
    }

    /// Import progression data
    func importProgressionData(_ data: Data) async throws {
        self.progressionDB = try JSONHelper.decode(WordProgressionDatabase.self, from: data)
        loadingState = .loaded
        markDirty()
        try await saveProgressionData()
        logger.log("Imported progression data")
    }
}

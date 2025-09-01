//  SessionStorageManager.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/31/25.
//

import Foundation
import OSLog

// MARK: - Constants

enum SessionStorageConstants {
    static let sessionsFilename = "sessions.json"
    static let backupFilename = "sessions_backup.json"
}

/// Manages persistent storage for practice session records
final class SessionStorageManager: PracticeSessionStorage {
    private let logger = Logger.sessionStorage

    private let dataStorage: DataStorageManager
    private let sessionsFilename = SessionStorageConstants.sessionsFilename

    // MARK: - Initialization

    init(dataStorage: DataStorageManager) {
        self.dataStorage = dataStorage
    }

    // MARK: - PracticeSessionStorage Implementation

    /// Saves a completed session record to persistent storage
    func saveSessionRecord(_ record: SessionRecord) async throws {
        logger.info("Saving session record \(record.id) for lesson \(record.lessonId)")

        var existingRecords = try loadAllSessionRecords()
        existingRecords.append(record)

        let directoryURL = dataStorage.directoryURL(for: .appData)
        try dataStorage.saveToJSON(existingRecords, to: sessionsFilename, in: directoryURL)

        logger.log("Successfully saved session record with \(record.wordAttempts.count) attempts")
    }

    /// Retrieves all session records for a specific lesson
    func getSessionRecords(for lessonId: UUID) async throws -> [SessionRecord] {
        logger.info("Loading session records for lesson \(lessonId)")

        let allRecords = try loadAllSessionRecords()
        let filtered = allRecords.filter { $0.lessonId == lessonId }

        logger.log("Found \(filtered.count) session records for lesson \(lessonId)")
        return filtered
    }

    // MARK: - Private Methods

    /// Loads all session records from storage
    private func loadAllSessionRecords() throws -> [SessionRecord] {
        let directoryURL = dataStorage.directoryURL(for: .appData)

        do {
            let records: [SessionRecord] = try dataStorage.loadFromJSON([SessionRecord].self,
                                                                       from: sessionsFilename,
                                                                       in: directoryURL)
            return records
        } catch {
            // If file doesn't exist (first run), return empty array
            if let nsError = error as? CocoaError,
               nsError.code == .fileReadNoSuchFile ||
                nsError.code == .fileNoSuchFile {
                logger.log("No existing session records found, starting fresh")
                return []
            }
            throw error
        }
    }

    // MARK: - Additional Utilities (if needed in future)

    /// Deletes all session records for a lesson (for cleanup)
    func deleteSessionRecords(for lessonId: UUID) async throws {
        logger.info("Deleting session records for lesson \(lessonId)")

        var existingRecords = try loadAllSessionRecords()
        existingRecords.removeAll { $0.lessonId == lessonId }

        let directoryURL = dataStorage.directoryURL(for: .appData)
        try dataStorage.saveToJSON(existingRecords, to: sessionsFilename, in: directoryURL)

        logger.log("Deleted all session records for lesson \(lessonId)")
    }

    /// Gets session statistics across all lessons (aggregated)
    func getSessionStatistics() async throws -> SessionStatistics {
        let allRecords = try loadAllSessionRecords()

        let totalSessions = allRecords.count
        let totalAttempts = allRecords.reduce(0) { $0 + $1.wordAttempts.count }
        let avgAccuracy = allRecords.isEmpty ? 0.0 :
            allRecords.map { $0.summary.overallAccuracy }.reduce(0, +) / Double(allRecords.count)

        let typeCounts = allRecords.reduce(into: [:]) { result, record in
            result[record.practiceType, default: 0] += 1
        }

        return SessionStatistics(totalSessions: totalSessions,
                               totalAttempts: totalAttempts,
                               averageAccuracy: avgAccuracy,
                               sessionsByType: typeCounts)
    }
}

// MARK: - Statistics Structure

struct SessionStatistics: Codable, Hashable {
    let totalSessions: Int
    let totalAttempts: Int
    let averageAccuracy: Double
    let sessionsByType: [PracticeType: Int]
}

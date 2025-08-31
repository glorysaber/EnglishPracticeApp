//
//  DataStorageManager.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/30/25.
//

import Foundation

/// Wrapper around FileManager for data persistence operations
/// Designed to be easily replaceable with Core Data, Realm, or other storage solutions
@MainActor
final class DataStorageManager {
    private let fileManager: FileManager
    private let logger: Logger
    private let baseURL: URL

    /// Directory structure for app data
    enum DirectoryType: String {
        case appData = "AppData"
        case profile = "Profile"

        var directoryName: String { rawValue }
    }

    private init(fileManager: FileManager = .default,
                 logger: Logger = .dataStorage) {
        self.fileManager = fileManager
        self.logger = logger

        // Base directory in user's Application Support folder
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.baseURL = appSupportURL.appendingPathComponent("EnglishPractice")

        createBaseDirectoryIfNeeded()
    }

    // MARK: - Directory Management

    /// Get URL for a directory type, creating it if necessary
    func directoryURL(for type: DirectoryType) -> URL {
        let directoryURL = baseURL.appendingPathComponent(type.directoryName)
        ensureDirectoryExists(at: directoryURL)
        return directoryURL
    }

    /// Get URL for user profile data
    func profileDirectoryURL(for userId: String = "default") -> URL {
        directoryURL(for: .profile).appendingPathComponent(userId)
    }

    /// Ensure a directory exists, creating it if necessary
    private func ensureDirectoryExists(at url: URL) {
        do {
            if !fileManager.fileExists(atPath: url.path) {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
                logger.log("Created directory: \(url.lastPathComponent)")
            }
        } catch {
            logger.error("Failed to create directory at \(url.path): \(error.localizedDescription)")
        }
    }

    /// Create the base directory structure
    private func createBaseDirectoryIfNeeded() {
        ensureDirectoryExists(at: baseURL)
    }

    // MARK: - File Operations

    /// Save Codable object to JSON file
    func saveToJSON<T: Encodable>(
        _ object: T,
        to filename: String,
        in directoryURL: URL,
        options: JSONSerialization.WritingOptions = .prettyPrinted
    ) throws {
        ensureDirectoryExists(at: directoryURL)
        let fileURL = directoryURL.appendingPathComponent(filename)

        do {
            let data = try JSONHelper.encode(object)
            try data.write(to: fileURL, options: .atomic)
            logger.log("Saved \(T.self) to \(filename)")
        } catch {
            logger.error("Failed to save \(T.self) to \(filename): \(error.localizedDescription)")
            throw error
        }
    }

    /// Load Codable object from JSON file
    func loadFromJSON<T: Decodable>(
        _ type: T.Type,
        from filename: String,
        in directoryURL: URL
    ) throws -> T {
        let fileURL = directoryURL.appendingPathComponent(filename)

        do {
            let data = try Data(contentsOf: fileURL)
            let object = try JSONHelper.decode(type, from: data)
            logger.log("Loaded \(T.self) from \(filename)")
            return object
        } catch {
            if (error as? CocoaError)?.code == .fileReadNoSuchFile {
                logger.log("File \(filename) does not exist, this may be expected")
                throw NSError(domain: "DataStorageManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found: \(filename)"])
            } else {
                logger.error("Failed to load \(T.self) from \(filename): \(error.localizedDescription)")
                throw error
            }
        }
    }

    /// Check if a file exists
    func fileExists(at filename: String, in directoryURL: URL) -> Bool {
        let fileURL = directoryURL.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// Delete a file
    func deleteFile(at filename: String, in directoryURL: URL) throws {
        let fileURL = directoryURL.appendingPathComponent(filename)

        do {
            try fileManager.removeItem(at: fileURL)
            logger.log("Deleted file: \(filename)")
        } catch {
            logger.error("Failed to delete file \(filename): \(error.localizedDescription)")
            throw error
        }
    }

    /// List all files in a directory
    func listFiles(in directoryURL: URL, withExtension fileExtension: String? = nil) throws -> [String] {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: directoryURL.path)
            let filtered = fileExtension == nil ? contents : contents.filter { $0.hasSuffix(fileExtension!) }
            return filtered.sorted()
        } catch {
            logger.error("Failed to list files in \(directoryURL.path): \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Bundle Resource Operations

    /// Copy file from bundle to directory if it doesn't exist
    func copyFromBundle(
        _ filename: String,
        from bundle: Bundle = .main,
        to directoryURL: URL,
        overwrite: Bool = false
    ) throws {
        ensureDirectoryExists(at: directoryURL)
        let destinationURL = directoryURL.appendingPathComponent(filename)

        // Skip if file exists and overwrite is false
        if !overwrite && fileManager.fileExists(atPath: destinationURL.path) {
            logger.log("Skipping copy for \(filename) - file already exists")
            return
        }

        guard let sourceURL = bundle.url(forResource: filename.replacingOccurrences(of: ".json", with: ""),
                                       withExtension: "json") else {
            throw NSError(domain: "DataStorageManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Bundle file not found: \(filename)"])
        }

        do {
            if overwrite {
                try fileManager.removeItem(at: destinationURL)
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                logger.log("Overwrote bundle file: \(filename)")
            } else {
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                logger.log("Copied bundle file: \(filename)")
            }
        } catch {
            logger.error("Failed to copy bundle file \(filename): \(error.localizedDescription)")
            throw error
        }
    }

    /// Copy multiple files from bundle
    func copyFilesFromBundle(
        _ filenames: [String],
        to directoryURL: URL,
        overwrite: Bool = false,
        bundle: Bundle = .main
    ) throws {
        for filename in filenames {
            try copyFromBundle(filename, from: bundle, to: directoryURL, overwrite: overwrite)
        }
    }

    // MARK: - Migration Support

    /// Migrate data from old structure to new (for future schema updates)
    func migrateIfNeeded() {
        // Placeholder for future migration logic
        // This would handle upgrading data structure versions
        logger.log("Running migration checks...")
    }

    // MARK: - Utilities

    /// Clean up old files (for maintenance)
    func cleanupOldFiles(olderThan days: Int = 30, in directoryURL: URL) throws {
        let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)

        do {
            let files = try listFiles(in: directoryURL)
            for filename in files {
                let fileURL = directoryURL.appendingPathComponent(filename)
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)

                if let modificationDate = attributes[.modificationDate] as? Date,
                   modificationDate < cutoffDate {
                    try fileManager.removeItem(at: fileURL)
                    logger.log("Cleaned up old file: \(filename)")
                }
            }
        } catch {
            logger.error("Failed to cleanup old files: \(error.localizedDescription)")
            throw error
        }
    }
}

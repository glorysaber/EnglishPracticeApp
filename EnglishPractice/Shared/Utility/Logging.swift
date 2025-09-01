//
//  Logging.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/16/25.
//

import Foundation
import OSLog

extension os.Logger {
    static let englishPractice = logger(category: "Default")
    static let view = logger(category: "View")
    static let dataStorage = logger(category: "DataStorage")
    static let sessionStorage = logger(category: "SessionStorage")
    static let backgroundTask = logger(category: "BackgroundTask")

    static func logger(category: String) -> os.Logger {
        os.Logger(subsystem: "com.StephenKacLozano.EnglishPractice", category: category)
    }
}

// This is to workaround a bug in Swift Previews
struct Logger: Sendable {
    private let logger: os.Logger

    static let englishPractice = Logger(logger: .englishPractice)
    static let view = Logger(logger: .view)
    static let dataStorage = Logger(logger: .dataStorage)
    static let sessionStorage = Logger(logger: .sessionStorage)
    static let backgroundTask = Logger(logger: .backgroundTask)

    static func logger(category: String) -> Logger {
        Logger(logger: os.Logger.logger(category: category))
    }

    func log(_ message: String) {
        logger.log("\(message)")
    }

    func info(_ message: String) {
        logger.info("\(message)")
    }

    func warning(_ message: String) {
        logger.warning("\(message)")
    }

    func error(_ message: String) {
        logger.error("\(message)")
    }

    func critical(_ message: String) {
        logger.critical("\(message)")
    }
}

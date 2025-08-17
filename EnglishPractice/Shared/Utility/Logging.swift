//
//  Logging.swift
//  EnglishPractice
//
//  Created by Admin on 8/16/25.
//

import Foundation
import OSLog

extension os.Logger {
    static let englishPractice = os.Logger(subsystem: "com.StephenKacLozano.EnglishPractice", category: "Default")
    static let view = os.Logger(subsystem: "com.StephenKacLozano.EnglishPractice", category: "View")
}

#if DEBUG
// This is to workaround a bug in Swift Previews
public struct Logger: Sendable {
    private let logger: os.Logger
    
    static var englishPractice: Logger { Logger(logger: .englishPractice) }
    static var view: Logger { Logger(logger: .view) }
    
    public func log(_ message: String) {
        logger.log("\(message)")
    }

    public func info(_ message: String) {
        logger.info("\(message)")
    }

    public func warning(_ message: String) {
        logger.warning("\(message)")
    }

    public func error(_ message: String) {
        logger.error("\(message)")
    }

    public func critical(_ message: String) {
        logger.critical("\(message)")
    }
}
#endif

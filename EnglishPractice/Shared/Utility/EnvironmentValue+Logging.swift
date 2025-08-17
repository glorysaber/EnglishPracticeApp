//
//  EnvironmentValue+Logging.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/16/25.
//

public import SwiftUI
import OSLog

public extension EnvironmentValues {
    /// Pushes a new view onto the stack.
    @Entry var logger: Logger = .view
}

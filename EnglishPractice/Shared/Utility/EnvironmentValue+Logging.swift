//
//  EnvironmentValue+Logging.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/16/25.
//

import SwiftUI
import OSLog

extension EnvironmentValues {
    /// Pushes a new view onto the stack.
    @Entry var logger: Logger = .view
}

//
//  EnvironmentValues+Logging.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/16/25.
//

import SwiftUI
#if DEBUG
import OSLog
#else
import OSLog
#endif

extension EnvironmentValues {
    /// Pushes a new view onto the stack.
    @Entry var logger: Logger = .view
}

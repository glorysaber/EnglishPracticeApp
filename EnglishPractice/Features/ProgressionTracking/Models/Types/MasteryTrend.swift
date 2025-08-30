//
//  MasteryTrend.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/31/25.
//

import Foundation

/// Performance trend indicator for word practice
enum MasteryTrend: String, Codable, Hashable {
    case improving = "improving"
    case stable = "stable"
    case regressing = "regressing"
    case unknown = "unknown"

    var trendMultiplier: Double {
        switch self {
        case .improving:
            return 1.2  // Boost priority for improving words
        case .stable:
            return 1.0  // Normal priority for stable words
        case .regressing:
            return 1.5  // Higher priority for regressing words
        case .unknown:
            return 1.0  // Default priority for new words
        }
    }

    var displayName: String {
        switch self {
        case .improving:
            return "Improving"
        case .stable:
            return "Stable"
        case .regressing:
            return "Needs Practice"
        case .unknown:
            return "New"
        }
    }
}

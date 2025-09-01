//
//  PresetPath.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/31/25.
//

import Foundation

/// Configuration for a complete preset learning path
struct PresetPath: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let difficulty: String
    let estimatedDuration: Int  // minutes
    let lessons: [Lesson]

    init(id: String, title: String, description: String, difficulty: String, estimatedDuration: Int, lessons: [Lesson]) {
        self.id = id
        self.title = title
        self.description = description
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.lessons = lessons
    }
}

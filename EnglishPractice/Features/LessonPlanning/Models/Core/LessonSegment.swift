//
//  LessonSegment.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/31/25.
//

import Foundation

/// Configuration for a single practice segment within a lesson
struct LessonSegment: Codable, Identifiable, Hashable {
    let id: UUID
    let practiceType: PracticeType
    let title: String?
    let description: String?
    let durationEstimate: Int  // minutes
    let wordList: [String]
    let objectives: [String]
    let ordering: Int  // sequence within lesson (1-based)

    init(id: UUID = UUID(),
         practiceType: PracticeType,
         title: String? = nil,
         description: String? = nil,
         durationEstimate: Int,
         wordList: [String],
         objectives: [String] = [],
         ordering: Int = 1) {
        self.id = id
        self.practiceType = practiceType
        self.title = title
        self.description = description
        self.durationEstimate = durationEstimate
        self.wordList = wordList
        self.objectives = objectives
        self.ordering = ordering
    }
}

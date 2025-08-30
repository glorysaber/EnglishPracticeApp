//
//  Lesson.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/31/25.
//

import Foundation

/// Configuration for an individual lesson with flexible practice segments
struct Lesson: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let durationEstimate: Int  // total minutes across all segments
    let segments: [LessonSegment]  // Multiple practice types in sequence
    let learningObjectives: [String]  // Overall lesson objectives

    /// Computed property for compatibility with single-practice lessons
    var firstSegment: LessonSegment? {
        segments.sorted { $0.ordering < $1.ordering }.first
    }

    /// For backwards compatibility - returns first segment's practice type
    var primaryPracticeType: PracticeType? {
        firstSegment?.practiceType
    }

    /// All unique words across all segments in this lesson
    var allWords: [String] {
        Set(segments.flatMap { $0.wordList }).sorted()
    }

    init(id: String,
         title: String,
         description: String,
         durationEstimate: Int,
         segments: [LessonSegment],
         learningObjectives: [String] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.durationEstimate = durationEstimate
        self.segments = segments.sorted { $0.ordering < $1.ordering }  // Ensure sorted by ordering
        self.learningObjectives = learningObjectives
    }

    /// Legacy initializer for single-practice lessons (backwards compatibility)
    init(id: String,
         title: String,
         description: String,
         practiceType: PracticeType,
         durationEstimate: Int,
         wordList: [String],
         learningObjectives: [String]) {
        self.id = id
        self.title = title
        self.description = description
        self.durationEstimate = durationEstimate
        self.learningObjectives = learningObjectives

        // Create single segment from legacy parameters
        let segment = LessonSegment(
            practiceType: practiceType,
            durationEstimate: durationEstimate,
            wordList: wordList,
            objectives: learningObjectives
        )
        self.segments = [segment]
    }
}

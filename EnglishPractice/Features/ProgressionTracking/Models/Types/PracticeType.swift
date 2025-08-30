//
//  PracticeType.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/30/25.
//

import Foundation

/// Types of practice exercises available in the app
enum PracticeType: String, Codable, CaseIterable, Hashable {
    case phonetic = "phonetic"     /// Practice phonetic spelling of Spanish words
    case speaking = "speaking"     /// Practice speaking exercises
    case numbers = "numbers"       /// Practice number recognition and pronunciation
    case vocabulary = "vocabulary" /// General vocabulary practice
    case listening = "listening"   /// Audio comprehension exercises

    var displayName: String {
        switch self {
        case .phonetic:
            return "Phonetic Spelling"
        case .speaking:
            return "Speaking Practice"
        case .numbers:
            return "Numbers & Math"
        case .vocabulary:
            return "Vocabulary"
        case .listening:
            return "Listening"
        }
    }

    var iconName: String {
        switch self {
        case .phonetic:
            return "character.cursor.ibeam"
        case .speaking:
            return "mic.fill"
        case .numbers:
            return "numbersign"
        case .vocabulary:
            return "book.fill"
        case .listening:
            return "volume.3.fill"
        }
    }
}

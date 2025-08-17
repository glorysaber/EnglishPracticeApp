//
//  PhoneticSpellingService.swift
//  EnglishPractice
//
//  Created by Admin on 8/17/25.
//

import Foundation
import Synchronization

struct PhoneticSpellingService: Sendable {
    
    struct LettersData: Codable {
        let esUs: [String: String]  // Matches the JSON structure: {"es-us": {"A": "ei", ...}}
        
        enum CodingKeys: String, CodingKey {
            case esUs = "es-us"
        }
    }
    
    private static let cache = Mutex(Optional<PhoneticSpellingService>.none)
    
    let letterToPhoneticMap: [Character: String]
    
    init(letterToPhoneticMap: [Character : String]) {
        self.letterToPhoneticMap = letterToPhoneticMap
    }
    
    init() throws {
        if let cache = PhoneticSpellingService.cache.withLock({$0}) {
            self = cache
            return
        }
        
        // Get the phonetic map from Phonetics.json
        guard let jsonURL = Bundle.main.url(forResource: "Phonetics", withExtension: "json") else {
            #if DEBUG
            fatalError("Failed to load Phonetics.json")
            #else
            // TODO: Make this localizable
            throw GeneralError(userDescritpion: "Failed to load Phonetics.json, please report this error.")
            #endif
        }
        
        let phoneticsData: Data = try Data(contentsOf: jsonURL)
        let lettersData: LettersData = try JSONDecoder().decode(LettersData.self, from: phoneticsData)
        
        var letterToPhoneticMap: [Character: String] = [:]
        for (letter, phonetic) in lettersData.esUs {
            letterToPhoneticMap[Character(letter)] = phonetic
        }
        
        self.letterToPhoneticMap = letterToPhoneticMap
        
        let cache = self
        PhoneticSpellingService.cache.withLock {
            if $0 == nil {
                $0 = cache
            }
        }
    }
}

//
//  PhoneticPracticeTests.swift
//  EnglishPracticeTests
//
//  Created by Stephen Kac Lozano on 8/31/25.
//

import Testing
@testable import EnglishPractice

struct PhoneticPracticeTests {

    @Test func testPhoneticSpellingServiceCache() async throws {
        // Test that the singleton cache works
        let service1 = try PhoneticSpellingService()
        let service2 = try PhoneticSpellingService()

        #expect(service1.letterToPhoneticMap.count == service2.letterToPhoneticMap.count)
        #expect(service1.letterToPhoneticMap["A"] == service2.letterToPhoneticMap["A"])
    }

    @Test func testPhoneticSpellingInitialization() async throws {
        let service = try PhoneticSpellingService()

        // Ensure essential letters are loaded
        #expect(service.letterToPhoneticMap["A"] != nil)
        #expect(service.letterToPhoneticMap["B"] != nil)
        #expect(service.letterToPhoneticMap["C"] != nil)

        // Ensure phonetic mappings are not empty
        #expect(!service.letterToPhoneticMap.isEmpty)
    }

    @Test func testManualPhoneticServiceInitialization() async throws {
        let customMap: [Character: String] = ["A": "alpha", "B": "bravo"]
        let service = PhoneticSpellingService(letterToPhoneticMap: customMap)

        #expect(service.letterToPhoneticMap["A"] == "alpha")
        #expect(service.letterToPhoneticMap["B"] == "bravo")
        #expect(service.letterToPhoneticMap["C"] == nil)
    }
}

//
//  ServiceTests.swift
//  EnglishPracticeTests
//
//  Created by Stephen Kac Lozano on 8/31/25.
//

import Testing
import Foundation
@testable import EnglishPractice

struct ServiceTests {

    // MARK: - JSONHelper Tests

    @Test func testJSONHelperEncode() throws {
        let testData = ["test": "value"]
        let json = try JSONHelper.encode(testData)
        #expect(json.isEmpty == false)

        // Verify it's valid JSON
        let decoded = try JSONHelper.decode([String: String].self, from: json)
        #expect(decoded == testData)
    }

    @Test func testJSONHelperDecode() throws {
        let jsonString = """
        {"key": "value"}
        """
        let jsonData = jsonString.data(using: .utf8)!

        let decoded = try JSONHelper.decode([String: String].self, from: jsonData)
        #expect(decoded["key"] == "value")
    }

    @Test func testJSONHelperInvalidData() async throws {
        let invalidData = "invalid json".data(using: .utf8)!

        do {
            _ = try JSONHelper.decode([String: String].self, from: invalidData)
            #expect(Bool(false), "Expected decoding to fail")
        } catch {
            // Expected to fail
            #expect(error is DecodingError)
        }
    }

    // MARK: - GeneralError Tests

    @Test func testGeneralErrorCreation() {
        let error = GeneralError(userDescritpion: "Test error")
        #expect(error.userDescritpion == "Test error")
    }

    @Test func testErrorDescription() {
        let error = GeneralError(userDescritpion: "Custom error message")
        #expect(error.userDescritpion == "Custom error message")
    }

    // MARK: - PracticeAttempt Tests

    @Test func testPracticeAttemptInitialization() {
        let sessionId = UUID()
        let timestamp = Date()
        let attempt = PracticeAttempt(
            accuracy: 0.85,
            timeSpent: 15.5,
            attempts: 2,
            hintsUsed: ["hint1", "hint2"],
            timestamp: timestamp,
            sessionId: sessionId
        )

        #expect(attempt.accuracy == 0.85)
        #expect(attempt.timeSpent == 15.5)
        #expect(attempt.attempts == 2)
        #expect(attempt.hintsUsed == ["hint1", "hint2"])
        #expect(attempt.timestamp == timestamp)
        #expect(attempt.sessionId == sessionId)
    }

    @Test func testPracticeAttemptEmptyHints() {
        let attempt = PracticeAttempt(
            accuracy: 1.0,
            timeSpent: 10.0,
            attempts: 1,
            hintsUsed: [],
            timestamp: Date(),
            sessionId: UUID()
        )

        #expect(attempt.hintsUsed.isEmpty)
    }

    // MARK: - Helper Types for Tests

    enum TestPlistCompatibleObject: Equatable, Codable {
        case string(String)
        case integer(Int)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else if let intValue = try? container.decode(Int.self) {
                self = .integer(intValue)
            } else {
                throw DecodingError.typeMismatch(TestPlistCompatibleObject.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unexpected type"))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .integer(let value):
                try container.encode(value)
            }
        }
    }
}

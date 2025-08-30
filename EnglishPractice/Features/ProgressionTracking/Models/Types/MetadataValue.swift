//
//  CustomCodable.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/30/25.
//

import Foundation

/// A flexible enum wrapper that can handle different JSON-compatible value types
/// Enables practice types to store custom metadata without schema changes
enum MetadataValue: Codable, Hashable {

    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
    case date(Date)
    case array([MetadataValue])
    case dictionary([String: MetadataValue])

    // MARK: - simple init methods
    static func intValue(_ value: Int) -> MetadataValue { .int(value) }
    static func doubleValue(_ value: Double) -> MetadataValue { .double(value) }
    static func stringValue(_ value: String) -> MetadataValue { .string(value) }
    static func boolValue(_ value: Bool) -> MetadataValue { .bool(value) }
    static func dateValue(_ value: Date) -> MetadataValue { .date(value) }
    static func arrayValue(_ value: [MetadataValue]) -> MetadataValue { .array(value) }
    static func dictionaryValue(_ value: [String: MetadataValue]) -> MetadataValue { .dictionary(value) }

    // MARK: - Convenience getters
    var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }

    var doubleValue: Double? {
        if case .double(let value) = self { return value }
        return nil
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var dateValue: Date? {
        if case .date(let value) = self { return value }
        return nil
    }

    var arrayValue: [MetadataValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    var dictionaryValue: [String: MetadataValue]? {
        if case .dictionary(let value) = self { return value }
        return nil
    }

    // MARK: - Codable implementation
    private enum CodingKeys: String, CodingKey {
        case type, value
    }

    private enum ValueType: String, Codable {
        case int, double, string, bool, date, array, dictionary
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .int(let value):
            try container.encode(ValueType.int, forKey: .type)
            try container.encode(value, forKey: .value)
        case .double(let value):
            try container.encode(ValueType.double, forKey: .type)
            try container.encode(value, forKey: .value)
        case .string(let value):
            try container.encode(ValueType.string, forKey: .type)
            try container.encode(value, forKey: .value)
        case .bool(let value):
            try container.encode(ValueType.bool, forKey: .type)
            try container.encode(value, forKey: .value)
        case .date(let value):
            try container.encode(ValueType.date, forKey: .type)
            try container.encode(value.ISO8601Format(), forKey: .value)
        case .array(let value):
            try container.encode(ValueType.array, forKey: .type)
            try container.encode(value, forKey: .value)
        case .dictionary(let value):
            try container.encode(ValueType.dictionary, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ValueType.self, forKey: .type)

        switch type {
        case .int:
            let value = try container.decode(Int.self, forKey: .value)
            self = .int(value)
        case .double:
            let value = try container.decode(Double.self, forKey: .value)
            self = .double(value)
        case .string:
            let value = try container.decode(String.self, forKey: .value)
            self = .string(value)
        case .bool:
            let value = try container.decode(Bool.self, forKey: .value)
            self = .bool(value)
        case .date:
            let dateString = try container.decode(String.self, forKey: .value)
            guard let date = try? Date.fromISO8601String(dateString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .value,
                    in: container,
                    debugDescription: "Invalid date format"
                )
            }
            self = .date(date)
        case .array:
            let value = try container.decode([MetadataValue].self, forKey: .value)
            self = .array(value)
        case .dictionary:
            let value = try container.decode([String: MetadataValue].self, forKey: .value)
            self = .dictionary(value)
        }
    }
}

// MARK: - Date extensions for JSON formatting
extension Date {
    /// Parse ISO8601 string to Date
    static func fromISO8601String(_ isoString: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: isoString) else {
            throw NSError(domain: "DateParsingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid ISO8601 date string"])
        }
        return date
    }

    /// Format Date to ISO8601 string
    func ISO8601Format() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: self)
    }
}

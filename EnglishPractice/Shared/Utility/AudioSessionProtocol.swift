//  AudioSessionProtocol.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 9/1/25.
//

import Foundation

/// Protocol defining platform-neutral audio session methods used by SpeechSynthesisService
protocol AudioSessionProtocol {
    /// Set the audio session category
    /// - Parameters:
    ///   - category: The category to set
    ///   - mode: The mode within the category
    ///   - options: Options for the session
    /// - Throws: An error if the operation fails
    func setCategory(_ category: AudioSessionCategory,
                    mode: AudioSessionMode,
                    options: AudioSessionOptions) throws

    /// Activate or deactivate the audio session
    /// - Parameter active: Whether to activate the session
    /// - Throws: An error if the operation fails
    func setActive(_ active: Bool) throws
}

/// Platform-neutral audio session categories
enum AudioSessionCategory {
    case playback  // For audio playback scenarios
}

/// Platform-neutral audio session modes
enum AudioSessionMode {
    case voicePrompt  // For voice-prompt like scenarios
}

/// Platform-neutral audio session options (flags)
struct AudioSessionOptions: OptionSet {
    let rawValue: Int

    static let duckOthers = AudioSessionOptions(rawValue: 1 << 0)  // Reduce other audio
}

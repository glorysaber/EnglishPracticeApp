//  AudioSessionFactory.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 9/1/25.
//

/// Factory for creating platform-appropriate AudioSession instances
final class AudioSessionFactory {
    /// Returns a platform-appropriate AudioSessionProtocol implementation
    static func createAudioSession() -> any AudioSessionProtocol {
        #if os(iOS)
        return iOSAudioSessionAdapter()
        #elseif os(macOS)
        return macOSAudioSessionAdapter()
        #else
        fatalError("Unsupported platform")
        #endif
    }
}

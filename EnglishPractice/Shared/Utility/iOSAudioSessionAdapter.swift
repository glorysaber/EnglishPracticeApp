//  iOSAudioSessionAdapter.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 9/1/25.
//

#if os(iOS)
import AVFoundation

/// iOS implementation using AVAudioSession
final class iOSAudioSessionAdapter: AudioSessionProtocol {
    private let audioSession = AVAudioSession.sharedInstance()

    func setCategory(_ category: AudioSessionCategory,
                    mode: AudioSessionMode,
                    options: AudioSessionOptions) throws {
        // Map platform-neutral types to AVAudioSession types
        let avCategory = avCategory(for: category)
        let avMode = avMode(for: mode)
        let avOptions = avOptions(for: options)

        try audioSession.setCategory(avCategory, mode: avMode, options: avOptions)
    }

    func setActive(_ active: Bool) throws {
        try audioSession.setActive(active)
    }

    // MARK: - Private Mapping Functions

    private func avCategory(for category: AudioSessionCategory) -> AVAudioSession.Category {
        switch category {
        case .playback:
            return .playback
        }
    }

    private func avMode(for mode: AudioSessionMode) -> AVAudioSession.Mode {
        switch mode {
        case .voicePrompt:
            return .voicePrompt
        }
    }

    private func avOptions(for options: AudioSessionOptions) -> AVAudioSession.CategoryOptions {
        var avOptions: AVAudioSession.CategoryOptions = []
        if options.contains(.duckOthers) {
            avOptions.insert(.duckOthers)
        }
        return avOptions
    }
}
#endif

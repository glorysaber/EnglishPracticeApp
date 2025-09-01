//  macOSAudioSessionAdapter.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 9/1/25.
//

#if os(macOS)
/// macOS implementation with no-op functions (macOS does not have AVAudioSession equivalent)
final class macOSAudioSessionAdapter: AudioSessionProtocol {
    func setCategory(_ category: AudioSessionCategory,
                    mode: AudioSessionMode,
                    options: AudioSessionOptions) throws {
        // No-op: macOS does not require explicit audio session configuration for speech synthesis
    }

    func setActive(_ active: Bool) throws {
        // No-op: macOS does not require explicit audio session activation for speech synthesis
    }
}
#endif

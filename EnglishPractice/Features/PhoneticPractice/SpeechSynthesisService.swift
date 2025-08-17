//
//  SpeechSynthesisService.swift
//  EnglishPractice
//
//  Created by Admin on 8/17/25.
//

import Foundation
import AVFoundation

@MainActor
struct SpeechSynthesisService: Sendable {
    let audioSession = AVAudioSession.sharedInstance()
    let synthesizer = AVSpeechSynthesizer()
    let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
        setupAudioSession()
    }
    
    func speak(word: String) {
        if synthesizer.isSpeaking {
            return
        }
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-US")
        utterance.rate = 0.01
        synthesizer.speak(utterance)
    }
    
    func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .voicePrompt, options: .duckOthers)
            try audioSession.setActive(true)
        } catch {
            logger.error("Error in setting up audio session: \(error)")
        }
    }
}

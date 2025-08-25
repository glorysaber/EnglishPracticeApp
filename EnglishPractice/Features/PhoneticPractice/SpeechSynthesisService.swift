//
//  SpeechSynthesisService.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/17/25.
//

import Foundation
import AVFoundation

@MainActor
final class SpeechSynthesisService: Sendable {
    typealias Stream = AsyncStream<SpeechSynthesisEvent>
    
    enum SpeechSynthesisError: Error {
        case alreadySpeaking
    }
    
    enum SpeechSynthesisEvent {
        case speaking
        case finished
    }
    
    static let shared = SpeechSynthesisService(logger: .englishPractice)
    
    private let audioSession = AVAudioSession.sharedInstance()
    private let synthesizer = AVSpeechSynthesizer()
    private let logger: Logger
    private let synthesizerDelegate: SpeechSynthesisServiceDelegate
    
    private init(logger: Logger) {
        self.logger = logger
        self.synthesizerDelegate = SpeechSynthesisServiceDelegate(logger: logger)
        setupAudioSession()
        
        synthesizer.delegate = synthesizerDelegate
    }
    
    func speak(utterance: String) throws(SpeechSynthesisError) -> AsyncStream<SpeechSynthesisEvent> {
        if synthesizer.isSpeaking {
            throw SpeechSynthesisError.alreadySpeaking
        }
        let utterance = AVSpeechUtterance(string: utterance)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.01
        
        let stream = Stream { continuation in
            self.synthesizerDelegate.utterances[utterance] = continuation
        }
        
        synthesizer.speak(utterance)
        
        return stream
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

@MainActor
private final class SpeechSynthesisServiceDelegate: NSObject, Sendable, @preconcurrency AVSpeechSynthesizerDelegate {
    
    let logger: Logger
    
    var utterances = [AVSpeechUtterance : SpeechSynthesisService.Stream.Continuation]()
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        guard let continuation = utterances[utterance] else {
            logger.error("Failed to find utterance for didStart \(utterance)")
            return
        }
        
        continuation.yield(.speaking)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard let continuation = utterances[utterance] else {
            logger.error("Failed to find utterance for didFinish \(utterance)")
            return
        }
        
        continuation.yield(.finished)
        continuation.finish()
        utterances[utterance] = nil
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        guard let continuation = utterances[utterance] else {
            logger.error("Failed to find utterance for cancellation \(utterance)")
            return
        }
        continuation.yield(.finished)
        continuation.finish()
        utterances[utterance] = nil
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeak marker: AVSpeechSynthesisMarker, utterance: AVSpeechUtterance) {
        
    }
}

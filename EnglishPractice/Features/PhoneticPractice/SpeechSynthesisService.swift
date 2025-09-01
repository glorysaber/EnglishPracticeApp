//
//  SpeechSynthesisService.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/17/25.
//

import Foundation
import AVFoundation
import os.log
import Synchronization
import Collections

final class SpeechSynthesisService: Sendable {
    typealias Stream = AsyncStream<Result<SpeechSynthesisEvent, SpeechSynthesisError>>

    enum SpeechSynthesisError: Error {
        case alreadySpeaking
        case internalError(String)
        case utteranceNotFound
    }

    enum SpeechSynthesisEvent {
        case speaking
        case scheduled
        case finished
    }

    static let shared = SpeechSynthesisService(logger: .englishPractice)

    private let logger: Logger
    private let synthesizer: AVSpeechSynthesisService

    private init(logger: Logger) {
        self.logger = logger
        self.synthesizer = AVSpeechSynthesisService(logger: logger)
    }

    func speak(utterance: String) -> Stream {
        synthesizer.speak(utterance: utterance)
    }
}

private actor AVSpeechSynthesisService: NSObject, Sendable {

    typealias Stream = SpeechSynthesisService.Stream

    typealias Continuation = Stream.Continuation

    typealias SpeechSynthesisError = SpeechSynthesisService.SpeechSynthesisError

    private let audioSession: any AudioSessionProtocol = AudioSessionFactory.createAudioSession()
    private let synthesizer = AVSpeechSynthesizer()

    private let taskQueue = TaskQueue()

    let logger: Logger

    var utterances = [AVSpeechUtterance: Continuation]()

    init(logger: Logger) {
        self.logger = logger
        super.init()
        synthesizer.delegate = self
    }

    func speak(utterance: String) -> AsyncStream<Result<SpeechSynthesisEvent, SpeechSynthesisError>> {

        let utterance = AVSpeechUtterance(string: utterance)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.01

        let stream = AsyncStream<Result<SpeechSynthesisEvent, SpeechSynthesisError>> { continuation in
            utterances[utterance] = continuation

            Task(priority: .utility) {
                if synthesizer.isSpeaking {
                    continuation.yield(.failure(.alreadySpeaking))
                    continuation.finish()
                    utterances[utterance] = nil
                    return
                }

                synthesizer.speak(utterance)
            }
        }

        return stream
    }
}

extension AVSpeechSynthesisService: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard let continuation = utterances[utterance] else {
                logger.critical("No continuation for utterance \(utterance)")
                return
            }
            continuation.yield(.success(.speaking))
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard let continuation = utterances[utterance] else {
                logger.critical("No continuation for utterance \(utterance)")
                return
            }

            continuation.yield(.success(.finished))
            continuation.finish()
            utterances[utterance] = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard let continuation = utterances[utterance] else {
                logger.critical("No continuation for utterance \(utterance)")
                return
            }

            continuation.yield(.success(.finished))
            continuation.finish()
            utterances[utterance] = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {

    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {

    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {

    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeak marker: AVSpeechSynthesisMarker, utterance: AVSpeechUtterance) {

    }
}

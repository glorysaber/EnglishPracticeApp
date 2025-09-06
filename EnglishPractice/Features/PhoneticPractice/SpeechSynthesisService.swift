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
    typealias Stream = AsyncThrowingStream<SpeechSynthesisEvent, any Error>

    enum SpeechSynthesisError: Error, LocalizedError {
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

    var idByUtterance = [AVSpeechUtterance : UUID]()
    var utteranceByID = [UUID : AVSpeechUtterance]()
    var continuationByUUID = [UUID : Continuation]()

    init(logger: Logger) {
        self.logger = logger
        super.init()
        synthesizer.delegate = self
    }

    fileprivate nonisolated func makeUtterance(string: String) -> UUID {
        let uuid = UUID()

        taskQueue.async() {
            await self._makeUtterance(string: string, with: uuid)
        }

        return uuid
    }

    private func _makeUtterance(string: String, with id: UUID) {
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.01

        idByUtterance[utterance] = id
        utteranceByID[id] = utterance
    }
}

extension AVSpeechSynthesisService {
    nonisolated func speak(utterance: String) -> Stream {
        taskQueue.async {
            await self.setupAudioSessionIfNeeded()
        }

        let utteranceUUID = makeUtterance(string: utterance)

        let stream = Stream { continuation in
            taskQueue.async {
                await self.setContinuation(continuation, for: utteranceUUID)
            }
        }

        taskQueue.async { [self] in
            await _speakUtterance(for: utteranceUUID)
        }

        return stream
    }

    private func _speakUtterance(for id: UUID) {
        if synthesizer.isSpeaking {
            finishUtterance(id, throwingError: SpeechSynthesisError.alreadySpeaking)
            return
        }

        guard let utterance = utteranceByID[id] else {
            finishUtterance(id, throwingError: SpeechSynthesisError.utteranceNotFound)
            return
        }

        synthesizer.speak(utterance)
    }

    private func setupAudioSessionIfNeeded() {
        if audioSession.isActive {
            return
        }

        do {
            try audioSession.setCategory(.playback, mode: .voicePrompt, options: .duckOthers)
            try audioSession.setActive(true)
        } catch {
            logger.error("Error in sett ing up audio session: \(error)")
        }
    }
}

extension AVSpeechSynthesisService: AVSpeechSynthesizerDelegate {

    func setContinuation(_ continuation: sending Continuation, for id: UUID) {
        continuationByUUID[id] = continuation
    }

    func sendEvent(_ event: SpeechSynthesisService.Stream.Element, for id: UUID) {
        guard let continuation = continuationByUUID[id] else {
            logger.error("Failed to find utterance for sendEvent \(id)")
            return
        }
        continuation.yield(event)
    }

    func getID(for utterance: AVSpeechUtterance) -> UUID? {
        idByUtterance[utterance]
    }

    func finishUtterance(_ id: UUID, throwingError error: SpeechSynthesisError? = nil) {
        guard let continuation = continuationByUUID[id] else {
            logger.error("Failed to find continuation for id \(id)")
            return
        }

        if let error {
            continuation.finish(throwing: error)
        } else {
            continuation.yield(.finished)
            continuation.finish()
        }
        continuationByUUID[id] = nil
        if let utterance = utteranceByID[id] {
            utteranceByID[id] = nil
            idByUtterance[utterance] = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let utteranceIdentifier = ObjectIdentifier(utterance)
        Task { @MainActor in
            await self.handleDelegateEvent(.started, utteranceIdentifier: utteranceIdentifier)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let utteranceIdentifier = ObjectIdentifier(utterance)
        Task { @MainActor in
            await self.handleDelegateEvent(.finished, utteranceIdentifier: utteranceIdentifier)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let utteranceIdentifier = ObjectIdentifier(utterance)
        Task { @MainActor in
            await self.handleDelegateEvent(.cancelled, utteranceIdentifier: utteranceIdentifier)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {

    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {

    }

    private func handleDelegateEvent(_ event: DelegateEvent, utteranceIdentifier: ObjectIdentifier) {
        // Find the utterance by iterating through the existing mapping
        // Since we can't pass AVSpeechUtterance across isolation domains, we need to find it by identifier
        var foundID: UUID?
        for (utterance, id) in idByUtterance {
            if ObjectIdentifier(utterance) == utteranceIdentifier {
                foundID = id
                break
            }
        }

        guard let id = foundID else {
            logger.error("Could not find ID for utterance identifier in handleDelegateEvent")
            return
        }

        switch event {
        case .started:
            sendEvent(.speaking, for: id)
        case .finished:
            finishUtterance(id)
        case .cancelled:
            finishUtterance(id)
        }
    }

    private enum DelegateEvent {
        case started
        case finished
        case cancelled
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {

    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeak marker: AVSpeechSynthesisMarker, utterance: AVSpeechUtterance) {

    }
}

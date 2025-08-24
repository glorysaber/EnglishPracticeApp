//
//  PhoneticPracticeViewModel.swift
//  EnglishPractice
//
//  Created by Admin on 8/17/25.
//

import Foundation
import OSLog

@MainActor
struct PhoneticPracticeViewModel: Sendable {
    let logger: Logger
    let speechService: SpeechSynthesisService
    let viewState: PhoneticPracticeViewState
    let phoneticService = try? PhoneticSpellingService()
    
    init(
        logger: Logger,
        speechService: SpeechSynthesisService,
        viewState: PhoneticPracticeViewState
    ) {
        self.logger = logger
        self.speechService = speechService
        self.viewState = viewState
        
        setup()
    }
    
    func setup() {
        viewState.word = "Mujer"
        if let phoneticService {
            // make upper case then look up
            viewState.phoneticLetters = viewState.word.compactMap { phoneticService.letterToPhoneticMap[Character(String($0).uppercased())] }
        }
    }
    
    @MainActor
    func speak() {
        Task {
            for (index, letter) in viewState.word.enumerated() {
                viewState.currentSpeakingIndex = index
                guard let stream = try? speechService.speak(utterance: String(letter.lowercased())) else { continue }
                for await event in stream {
                    if case .finished = event {
                        break
                    }
                }
                viewState.currentSpeakingIndex = nil
                try? await ContinuousClock().sleep(for: .seconds(1))
            }
        }
    }
    
    func checkGuess() {
        let isCorrect = viewState.guess.lowercased() == viewState.word.lowercased()
        viewState.practiceState = .finished(correct: isCorrect)
        viewState.showAnswer = true
    }
}

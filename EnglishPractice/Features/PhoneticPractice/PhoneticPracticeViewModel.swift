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
        speechService.speak(word: viewState.word)
    }
}

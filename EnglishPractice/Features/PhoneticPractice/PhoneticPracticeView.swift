//
//  PhoneticPracticeView.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/13/25.
//

import SwiftUI
import AVFoundation
import OSLog

@MainActor
@Observable
final class PhoneticPracticeViewState {
    var isPressed = false
}

let spanishPhoneticToEnglishLetter: [String: String] = [
    "A": "ei",
    "B": "bi",
    "C": "si",
    "D": "di",
    "E": "i",
    "F": "ef",
    "G": "yi",
    "H": "eich",
    "I": "ai",
    "J": "yei",
    "K": "kei",
    "L": "el",
    "M": "em",
    "N": "en",
    "O": "ou",
    "P": "pi",
    "Q": "kiu",
    "R": "ar",
    "S": "es",
    "T": "ti",
    "U": "iu",
    "V": "vi",
    "W": "dabeliu",
    "X": "ex",
    "Y": "wai",
    "Z": "zi"
    ]

struct PhoneticPracticeView: View {
    let audioSession = AVAudioSession.sharedInstance()
    let synthesizer = AVSpeechSynthesizer()
    
    let word = "Mujer"
    
    var phoneticLetters: String {
        word.uppercased().reduce("") { result, letter in
            result + " " + (spanishPhoneticToEnglishLetter[String(letter)] ?? String(letter))
        }
    }
    
    @State private var state = PhoneticPracticeViewState()
    
    let logger: Logger
    
    var body: some View {
        VStack(spacing: 20) {
            Text(verbatim: "What word is this?")
            if state.isPressed {
                Text(verbatim: word)
            } else {
                Text(verbatim: phoneticLetters)
            }
            Button("Speak") {
                speak()
            }
            .buttonStyle(.borderedProminent)
            .task { setupAudioSession() }
//            Button {} label: {
                Text("Answer")
                    .onLongPressGesture {
                        if state.isPressed == false {
                            speakWord()
                            state.isPressed = true
                        }
                    } onPressingChanged: { pressed in
                        state.isPressed = pressed
                    }
//            }
//            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    func speak() {
        if synthesizer.isSpeaking {
            return
        }
        let utterance = AVSpeechUtterance(string: phoneticLetters)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-US")
        utterance.rate = 0.01
        synthesizer.speak(utterance)
            
    }
    
    func speakWord() {
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.001
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

#Preview {
    PhoneticPracticeView(logger: .view)
}

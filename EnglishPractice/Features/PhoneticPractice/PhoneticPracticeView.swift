//
//  PhoneticPracticeView.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/13/25.
//

import SwiftUI
import OSLog

@MainActor
@Observable
final class PhoneticPracticeViewState {
    var isPressed = false
    var word = ""
    var phoneticLetters: [String] = []
}

struct PhoneticPracticeView: View {
    
    @State private var state = PhoneticPracticeViewState()
    private let viewModel: PhoneticPracticeViewModel
    
    @Environment(\.pop) private var pop
    
    private var logger: Logger
    
    var body: some View {
        VStack(spacing: 20) {
            Text(verbatim: "What word is this?")
                .font(.largeTitle)
            if state.isPressed {
                Text(verbatim: state.word)
                    .font(.subheadline)
            } else {
                Text(verbatim: state.phoneticLetters.joined(separator: " "))
                    .font(.subheadline)
            }
            Button("Speak") {
                viewModel.speak()
            }
            .buttonStyle(.borderedProminent)
            Text("Answer")
                .onLongPressGesture {
                    if state.isPressed == false {
                        viewModel.speak()
                        state.isPressed = true
                    }
                } onPressingChanged: { pressed in
                    state.isPressed = pressed
                }
            Button {
                pop()
            } label: {
                Text("Pop").padding()
            }
        }
        .padding()
        .background(Color.blue)
        .padding()
    }
    
    init(initialState: PhoneticPracticeViewState = PhoneticPracticeViewState(), logger: Logger = .view) {
        self.state = initialState
        self.logger = logger
        self.viewModel = PhoneticPracticeViewModel(logger: logger, speechService: SpeechSynthesisService(logger: logger), viewState: initialState)
    }
}

#Preview {
    PhoneticPracticeView()
}

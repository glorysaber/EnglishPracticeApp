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
    @Environment(\.colorPalatte) private var colorPalatte
    
    private var logger: Logger
    
    private var wordLabel: some View {
        if state.isPressed {
            Text(verbatim: state.word)
                .font(.subheadline)
        } else {
            Text(verbatim: state.phoneticLetters.joined(separator: " "))
                .font(.subheadline)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(verbatim: "What word is this?")
                .font(.largeTitle)
                .foregroundStyle(colorPalatte.text.body)
            HStack {
                wordLabel
                    .foregroundStyle(colorPalatte.text.body)
                Button {
                    viewModel.speak()
                } label: {
                    Image(systemName: "play.fill")
                        .accessibilityLabel("Play")
                        .foregroundStyle(colorPalatte.text.body)
                }
            }
            
            Text("Answer")
                .foregroundStyle(colorPalatte.text.body)
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
                    .foregroundStyle(colorPalatte.text.body)
            }
            .foregroundStyle(colorPalatte.button.background)
        }
        .padding()
        .background(colorPalatte.card.background)
        .padding()
    }
    
    init(initialState: PhoneticPracticeViewState = PhoneticPracticeViewState(), logger: Logger = .view) {
        self.state = initialState
        self.logger = logger
        self.viewModel = PhoneticPracticeViewModel(logger: logger, speechService: .shared, viewState: initialState)
    }
}

#Preview {
    PhoneticPracticeView()
}

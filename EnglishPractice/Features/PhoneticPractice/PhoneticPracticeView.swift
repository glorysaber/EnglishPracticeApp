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
    @Environment(\.colorPalette) private var colorPalette
    
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
                .foregroundStyle(colorPalette.text.body)
            HStack {
                wordLabel
                    .foregroundStyle(colorPalette.text.body)
                Button {
                    viewModel.speak()
                } label: {
                    Image(systemName: "play.fill")
                        .accessibilityLabel("Play")
                        .foregroundStyle(colorPalette.text.body)
                }
            }
            
            Text("Answer")
                .foregroundStyle(colorPalette.text.body)
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
                    .foregroundStyle(colorPalette.text.body)
            }
            .foregroundStyle(colorPalette.button.background)
        }
        .padding()
        .background(colorPalette.card.background)
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

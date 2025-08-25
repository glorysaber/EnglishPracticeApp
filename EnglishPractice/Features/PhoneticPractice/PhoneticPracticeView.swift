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
    var currentSpeakingIndex: Int? = nil
    var guess: String = ""
    var showAnswer = false
    
    enum PracticeState: Equatable {
        case guessing
        case finished(correct: Bool)
    }
    
    var practiceState: PracticeState = .guessing
}

struct PhoneticPracticeView: View {
    
    let cancelButtonAction: () -> Void
    
    @State private var state = PhoneticPracticeViewState()
    private let viewModel: PhoneticPracticeViewModel
    
    @Environment(\.colorPalette) private var colorPalette
    
    private var logger: Logger
    
    @State private var gradientColor: Color = .purple
    @State private var endPoint: UnitPoint = .init(x: 1, y: 0.2)
    
    private var phoneticDisplay: some View {
        HStack(spacing: 12) {
            ForEach(state.phoneticLetters.indices, id: \.self) { index in
                Text(state.phoneticLetters[index])
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        state.currentSpeakingIndex == index
                            ? colorPalette.pop.opacity(0.8)
                            : colorPalette.card.background.opacity(0.3)
                    )
                    .foregroundStyle(colorPalette.text.body)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .scaleEffect(state.currentSpeakingIndex == index ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: state.currentSpeakingIndex)
                    .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), radius: 2)
            }
        }
        .padding()
    }
    
    private var wordDisplay: some View {
        Text(state.word)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(colorPalette.text.body)
    }
    
    @ViewBuilder
    private var feedback: some View {
        switch state.practiceState {
        case .guessing:
            EmptyView()
        case .finished(let correct):
            Text(correct ? "Correct!" : "Try Again!")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(correct ? colorPalette.grow : colorPalette.pop)
                .padding(.top, 12)
                .transition(.opacity)
                .animation(.easeIn, value: state.practiceState)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(colors: [gradientColor, colorPalette.gradient.end], startPoint: .bottom, endPoint: endPoint)
            .ignoresSafeArea()
            .onChange(of: colorPalette, initial: true) { oldValue, newValue in
                gradientColor = colorPalette.gradient.start
                withAnimation(
                    Animation.easeInOut(duration: 10.0)
                        .repeatForever(autoreverses: true)
                ) {
                    gradientColor = colorPalette.gradient.start2
                    endPoint = .init(x: 0, y: 0.1)
                }
            }
    }
    
    private var guessInput: some View {
        Group {
            if case .guessing = state.practiceState {
                TextField("Your guess", text: $state.guess)
                    .textFieldStyle(.roundedBorder)
                    .foregroundStyle(colorPalette.text.body)
                    .background(colorPalette.card.background)
                    .padding(.horizontal, 40)
                    .shadow(radius: 4)
                
                Button("Submit Guess") {
                    viewModel.checkGuess()
                }
                .font(.headline)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(colorPalette.button.background)
                .foregroundStyle(colorPalette.text.overlay)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 24) {
                Text("What word is this?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(colorPalette.text.body)
                
                HStack {
                    if state.isPressed || state.showAnswer {
                        wordDisplay
                    } else {
                        phoneticDisplay
                    }
                    Button {
                        viewModel.speak()
                    } label: {
                        Image(systemName: "play.fill")
                            .accessibilityLabel("Play")
                            .foregroundStyle(colorPalette.text.body)
                            .padding(12)
                            .background(colorPalette.button.background.opacity(0.3))
                            .clipShape(Circle())
                            .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), radius: 4)
                    }
                }
                
                guessInput
                
                feedback
                
                Text("Hold to Reveal Answer")
                    .font(.subheadline)
                    .foregroundStyle(colorPalette.text.body.opacity(0.7))
                    .padding(8)
                    .background(colorPalette.background.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onLongPressGesture {
                        if !state.isPressed {
                            viewModel.speak()
                            state.isPressed = true
                            state.showAnswer = true
                        }
                    } onPressingChanged: { pressed in
                        state.isPressed = pressed
                    }
                
                Button {
                    cancelButtonAction()
                } label: {
                    Text("Cancel").padding(.horizontal, 20).padding(.vertical, 10)
                        .foregroundStyle(colorPalette.text.overlay)
                }
                .background(colorPalette.button.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2), radius: 4)
            }
            .padding(20)
            .background(colorPalette.card.background)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2), radius: 10)
            .padding()
        }
        
    }
    
    init(initialState: PhoneticPracticeViewState = PhoneticPracticeViewState(), logger: Logger = .view, cancelButtonAction: @escaping () -> Void) {
        self.state = initialState
        self.logger = logger
        self.cancelButtonAction = cancelButtonAction
        self.viewModel = PhoneticPracticeViewModel(logger: logger, speechService: .shared, viewState: initialState)
    }
}

#Preview {
    PhoneticPracticeView(cancelButtonAction: {}).adaptiveColorPalette(manager: ._debugManager())
}

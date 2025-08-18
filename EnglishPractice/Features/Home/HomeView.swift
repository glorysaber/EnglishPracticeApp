//
//  HomeView.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/15/25.
//

import SwiftUI
import OSLog

struct HomeView: View {
    
    let buttonAction: () -> Void
    
    var backgroundColor: Color {
        colorScheme == .light ? .white : .black
    }
    
    @State var gradientColor: Color = .primaryGradient
    
    @Environment(\.push) var push
    @Environment(\.logger) var logger
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Text("Current Streak 0!").font(.subheadline).fontWeight(.bold).foregroundColor(.white)
            gradientBackground
            VStack(spacing: 20) {
                Text("Ready to practice English?")
                    .font(.largeTitle)
                    .foregroundStyle(Color.mainBodyText)
                Button {
                    buttonPressed()
                } label: {
                    Text("Let's Start Practice!")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .accentColor(.accentButton)
            }
            .padding(25)
            .background(Color.backgroundCard.clipShape(CustomCardShape()))
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: -2)
        }
    }
    
    private func buttonPressed() {
        logger.log("Practice English Button pressed")
        buttonAction()
        push(AnyView(PhoneticPracticeView()))
    }
    
    @ViewBuilder
    var gradientBackground: some View {
        LinearGradient(gradient: Gradient(colors: [gradientColor, backgroundColor]), startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 10.0)
                        .repeatForever(autoreverses: true)
                ) {
                    // Get color from assets
                    gradientColor = .secondaryGradient
                }
            }
    }
}

#Preview {
    HomeView(buttonAction: {})
}

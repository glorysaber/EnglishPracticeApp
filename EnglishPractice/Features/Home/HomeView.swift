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
    
    @State var gradientColor: Color = .green
    @State var endPoint: UnitPoint = .bottomTrailing
    
    var overlayColor: Color {
        colorPalette.text.overlay
    }
    
    @Environment(\.push) var push
    @Environment(\.logger) var logger
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.colorPalette) var colorPalette
    
    var body: some View {
        ZStack {
            gradientBackground
            VStack(spacing: 30) {
                Text("Current Streak: 0 🔥")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(overlayColor)
                    .padding(.top, 50)
                
                Spacer()
                
                Image(systemName: "book.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .foregroundStyle(overlayColor.opacity(0.9))
                
                Text("Ready to practice English?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(overlayColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button {
                    buttonPressed()
                } label: {
                    Text("Let's Start Practice!")
                        .font(.headline)
                        .fontWeight(.medium)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(colorPalette.button.background)
                    .foregroundStyle(colorPalette.text.body)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                
                Spacer()
            }
            .padding(.bottom, 50)
        }
        .animation(.default, value: colorScheme)
    }
    
    init(buttonAction: @escaping () -> Void) {
        self.buttonAction = buttonAction
    }
    
    private func buttonPressed() {
        logger.log("Practice English Button pressed")
        buttonAction()
        push(AnyView(PhoneticPracticeView()))
    }
    
    @ViewBuilder
    var gradientBackground: some View {
        LinearGradient(gradient: Gradient(colors: [gradientColor, colorPalette.background]), startPoint: .top, endPoint: endPoint)
            .ignoresSafeArea()
            .onChange(of: colorPalette, initial: true) { oldValue, newValue in
                gradientColor = colorPalette.gradient.start
                withAnimation(
                    Animation.easeInOut(duration: 10.0)
                        .repeatForever(autoreverses: true)
                ) {
                    gradientColor = colorPalette.gradient.start2
                    endPoint = .bottomLeading
                }
            }
    }
}

#Preview {
    HomeView(buttonAction: {})
}

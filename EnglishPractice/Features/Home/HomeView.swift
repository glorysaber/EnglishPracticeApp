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
    
    @State var gradientColor: Color = .purple
    
    @Environment(\.push) var push
    @Environment(\.logger) var logger
    
    var body: some View {
        ZStack(alignment: .bottom) {
            gradientBackground
            VStack(spacing: 20) {
                Text("Ready to practice English?")
                    .font(.largeTitle)
                Button {
                    logger.log("Practice English Button pressed")
                    buttonAction()
                    push(AnyView(ContentView()))
                } label: {
                    Text("Lets Start practice!")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                Text("Current Streak 0!")
            }
            .padding()
            .background(Color.yellow.clipShape(CustomCardShape()))
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: -2)
        }
    }
    
    @ViewBuilder
    var gradientBackground: some View {
        LinearGradient(gradient: Gradient(colors: [gradientColor, .white]), startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 10.0)
                        .repeatForever(autoreverses: true)
                ) {
                    gradientColor = .blue
                }
            }
    }
}

#Preview {
    HomeView(buttonAction: {})
}

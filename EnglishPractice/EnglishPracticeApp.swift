//
//  EnglishPracticeApp.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/13/25.
//

import SwiftUI

enum AppRoutes: Hashable {
    case practiceView
    case text
}

@MainActor
private let colorManager = ColorPaletteManager(resource: Bundle.main.url(forResource: "Colors", withExtension: "json")!)

@MainActor
private let stackModel = SAKNavigationStackModel<AppRoutes>()

@main
struct EnglishPracticeApp: App {
    var body: some Scene {
        WindowGroup {
            SAKNavigationStackView(stackModel: stackModel) {
                HomeView {
                    stackModel.push(.practiceView)
                }
            } routeProvider: { route in
                switch route {
                case .practiceView:
                    PhoneticPracticeView {
                        stackModel.pop()
                    }
                case .text:
                    Text("Text")
                }
            }
            .adaptiveColorPalette(manager: colorManager)
        }
    }
}



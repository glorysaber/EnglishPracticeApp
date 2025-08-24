//
//  EnglishPracticeApp.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/13/25.
//

import SwiftUI

@main
struct EnglishPracticeApp: App {
    static let colorManager = ColorPaletteManager(resource: Bundle.main.url(forResource: "Colors", withExtension: "json")!)
    
    var body: some Scene {
        WindowGroup {
            SAKNavigationStack {
                HomeView(buttonAction: {})
            }
            .adaptiveColorPalette(manager: Self.colorManager)
        }
    }
}



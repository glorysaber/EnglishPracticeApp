//
//  EnglishPracticeApp.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/13/25.
//

import SwiftUI

@main
struct EnglishPracticeApp: App {
    @Environment(\.colorPalatte) var colorPalatte
    
    var body: some Scene {
        WindowGroup {
            SAKNavigationStack {
                HomeView(colorPalatte: colorPalatte, buttonAction: {})
            }
        }
    }
}



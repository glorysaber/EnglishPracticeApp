//
//  EnglishPracticeApp.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/13/25.
//

import SwiftUI
import OSLog

@main
struct EnglishPracticeApp: App {
    var body: some Scene {
        WindowGroup {
            SAKNavigationStack {
                HomeView(buttonAction: {})
            }
        }
    }
}



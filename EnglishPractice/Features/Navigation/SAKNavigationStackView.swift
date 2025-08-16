//
//  SAKNavigationStackView.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/16/25.
//

import SwiftUI
import OSLog

/// A custom navigation stack for SwiftUI that manages a stack of views with push/pop functionality.
/// Uses environment values for navigation actions and supports customizable transitions.
/// Optimized by minimizing view recreations and using efficient state management.
/// Uses @Entry macro for environment values to resolve concurrency issues in Swift 6.
struct SAKNavigationStack<Content: View>: View {
    /// Stack to hold navigated views with unique IDs for identity preservation.
    @State private var viewStack: [(id: UUID, view: AnyView)] = []
    
    /// The root view to display when the stack is empty.
    private let rootView: Content
    
    /// Customizable transition for navigation animations.
    private let transition: AnyTransition
    
    /// Initializes the navigation stack with a root view and optional transition.
    /// - Parameters:
    ///   - transition: The transition to use for push/pop (default: asymmetric slide with opacity).
    ///   - rootView: A view builder for the root content.
    init(transition: AnyTransition = .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
         ),
         @ViewBuilder rootView: () -> Content) {
        self.rootView = rootView()
        self.transition = transition
    }
    
    var body: some View {
        ZStack {
            // Display root view when stack is empty, with opacity transition for smooth root return.
            if viewStack.isEmpty {
                rootView
                    .transition(.opacity)
            } else {
                // Display the top view from the stack with the specified transition.
                viewStack.last?.view
                    .transition(transition)
            }
        }
        // Inject navigation actions into the environment for child views to use.
        .environment(\.push) { view in
            // Use spring animation for natural feel; optimized for performance with damping.
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                viewStack.append((UUID(), AnyView(view)))
            }
        }
        .environment(\.pop) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                _ = viewStack.popLast()
            }
        }
        .environment(\.popToRoot) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                viewStack.removeAll()
            }
        }
    }
}

// Environment values defined using @Entry to handle concurrency safely in Swift 6.
extension EnvironmentValues {
    /// Pushes a new view onto the stack.
    @Entry var push: (AnyView) -> Void = {
        _ in
        Logger.view.error("No Navigation Stack found when push was called. \(Thread.callStackSymbols)")
    }
    
    /// Pops the top view from the stack.
    @Entry var pop: () -> Void = {
        Logger.view.error("No Navigation Stack found when pop was called. \(Thread.callStackSymbols)")
    }
    
    /// Pops all views back to the root.
    @Entry var popToRoot: () -> Void = {
        Logger.view.error("No Navigation Stack found when popToRoot was called. \(Thread.callStackSymbols)")
    }
}

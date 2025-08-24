//
//  SAKNavigationStackView.swift
//  EnglishPractice
//
//  Created by Stephen Kac Lozano on 8/16/25.
//

import SwiftUI
import OSLog

// Custom modifier for vertical offset
struct VerticalPushModifier: ViewModifier {
    let offset: CGFloat  // Positive for bottom, negative for top
    
    func body(content: Content) -> some View {
        content.offset(y: offset)
    }
}

// Custom modifier for vertical offset
struct HorizantalPushModifier: ViewModifier {
    let offset: CGFloat  // Positive for bottom, negative for top
    
    func body(content: Content) -> some View {
        content.offset(x: offset)
    }
}

// Extension to create the transition
extension AnyTransition {
    @MainActor
    static func verticalPush(towards direction: SwiftUI.Edge = .top) -> AnyTransition {
        
        let offset: CGFloat = switch direction {
        case .top:
            UIScreen.main.bounds.height
        case .bottom:
            -UIScreen.main.bounds.height
        case .leading:
            UIScreen.main.bounds.width
        case .trailing:
            -UIScreen.main.bounds.width
        }
        
        
        return switch direction {
        case .top, .bottom:
                .asymmetric(
                    insertion: .modifier(
                        active: VerticalPushModifier(offset: offset),  // Start from bottom
                        identity: VerticalPushModifier(offset: 0)
                    ),
                    removal: .modifier(
                        active: VerticalPushModifier(offset: -offset),  // Slide to top
                        identity: VerticalPushModifier(offset: 0)
                    )
                )
        case .leading, .trailing:
                .asymmetric(
                    insertion: .modifier(
                        active: HorizantalPushModifier(offset: offset),  // Start from bottom
                        identity: HorizantalPushModifier(offset: 0)
                    ),
                    removal: .modifier(
                        active: HorizantalPushModifier(offset: -offset),  // Slide to top
                        identity: HorizantalPushModifier(offset: 0)
                    )
                )
        }
    }
}

enum NavigationDirection {
    case push, pop
}

/// A custom navigation stack for SwiftUI that manages a stack of views with push/pop functionality.
/// Uses environment values for navigation actions and supports customizable transitions.
/// Optimized by minimizing view recreations and using efficient state management.
/// Uses @Entry macro for environment values to resolve concurrency issues in Swift 6.
struct SAKNavigationStack<Content: View>: View {
    /// Stack to hold navigated views with unique IDs for identity preservation.
    @State private var viewStack: [(id: UUID, view: AnyView)] = []
    
    /// Direction of the navigation action to determine the transition.
    @State private var navigationDirection: NavigationDirection = .push
    
    /// The root view to display when the stack is empty.
    private let rootView: Content
    
    /// Initializes the navigation stack with a root view.
    /// - Parameter rootView: A view builder for the root content.
    init(@ViewBuilder rootView: () -> Content) {
        self.rootView = rootView()
    }
    
    /// Computes the dynamic transition based on navigation direction.
    private func dynamicTransition() -> AnyTransition {
        let insertion: AnyTransition = navigationDirection == .push ? .verticalPush(towards: .top) : .verticalPush(towards: .bottom)
        let removal: AnyTransition = navigationDirection == .push ? .verticalPush(towards: .top) : .verticalPush(towards: .bottom)
        return .asymmetric(
            insertion: insertion,
            removal: removal
        )
    }
    
    var body: some View {
        ZStack {
            // Display root view when stack is empty, with opacity transition for smooth root return.
            if viewStack.isEmpty {
                rootView
                    .transition(dynamicTransition())
            } else {
                // Display the top view from the stack with the dynamic transition.
                viewStack.last?.view
                    .transition(dynamicTransition())
            }
        }
        // Inject navigation actions into the environment for child views to use.
        .environment(\.push) { view in
            // Set direction to push and animate.
            navigationDirection = .push
            withAnimation(.easeInOut(duration: 10)) {
                viewStack.append((UUID(), AnyView(view)))
            }
        }
        .environment(\.pop) {
            // Set direction to pop and animate.
            navigationDirection = .pop
            withAnimation(.easeInOut) {
                _ = viewStack.popLast()
            }
        }
        .environment(\.popToRoot) {
            // Set direction to pop and animate.
            navigationDirection = .pop
            withAnimation(.spring()) {
                viewStack.removeAll()
            }
        }
    }
}

// Environment values defined using @Entry to handle concurrency safely in Swift 6.
extension EnvironmentValues {
    /// Pushes a new view onto the stack.
    @Entry var push: (AnyView) -> Void = { _ in
        Logger.view.error("No Navigation Stack found when push was called. \(Thread.callStackSymbols)")
        #if DEBUG
        fatalError()
        #endif
    }
    
    /// Pops the top view from the stack.
    @Entry var pop: () -> Void = {
        Logger.view.error("No Navigation Stack found when pop was called. \(Thread.callStackSymbols)")
        #if DEBUG
        fatalError()
        #endif
    }
    
    /// Pops all views back to the root.
    @Entry var popToRoot: () -> Void = {
        Logger.view.error("No Navigation Stack found when popToRoot was called. \(Thread.callStackSymbols)")
        #if DEBUG
        fatalError()
        #endif
    }
}

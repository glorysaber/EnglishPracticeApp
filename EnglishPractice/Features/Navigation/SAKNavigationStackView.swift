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
    static func verticalPush(towards direction: SwiftUI.Edge = .top, size: CGSize) -> AnyTransition {
        
        let offset: CGFloat = switch direction {
        case .top:
            size.height
        case .bottom:
            -size.height
        case .leading:
            size.width
        case .trailing:
            -size.width
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

@Observable
final class SAKNavigationStackModel<Route: Hashable> {
    fileprivate var routeStack: [(Route, UUID)] = []
    fileprivate var navigationDirection: NavigationDirection = .push
    
    func push(_ route: Route) {// Set direction to push and animate.
        navigationDirection = .push
        withAnimation(.easeInOut) {
            routeStack.append((route, UUID()))
        }
    }
    
    func pop() {
        navigationDirection = .pop
        withAnimation(.easeInOut) {
            _ = routeStack.popLast()
        }
    }
    
    func popToRoot() {
        navigationDirection = .pop
        withAnimation(.spring()) {
            routeStack.removeAll()
        }
    }
}

/// A custom navigation stack for SwiftUI that manages a stack of views with push/pop functionality.
/// Uses environment values for navigation actions and supports customizable transitions.
/// Optimized by minimizing view recreations and using efficient state management.
/// Uses @Entry macro for environment values to resolve concurrency issues in Swift 6.
struct SAKNavigationStackView<Content: View, Route: Hashable, RouteView: View>: View {
    
    @State private var stackModel: SAKNavigationStackModel<Route>
    
    @State private var containerSize: CGSize = .zero
    
    @ViewBuilder
    private let rootView: Content
    
    @ViewBuilder
    private let routeProvider: (Route) -> RouteView
    
    init(stackModel: SAKNavigationStackModel<Route>, @ViewBuilder rootView: () -> Content, @ViewBuilder routeProvider: @escaping (Route) -> RouteView) {
        self.stackModel = stackModel
        self.rootView = rootView()
        self.routeProvider = routeProvider
    }
    
    /// Computes the dynamic transition based on navigation direction.
    private func dynamicTransition() -> AnyTransition {
        let insertion: AnyTransition = stackModel.navigationDirection == .push ? .verticalPush(towards: .top, size: containerSize) : .verticalPush(towards: .bottom, size: containerSize)
        let removal: AnyTransition = stackModel.navigationDirection == .push ? .verticalPush(towards: .top, size: containerSize) : .verticalPush(towards: .bottom, size: containerSize)
        return .asymmetric(
            insertion: insertion,
            removal: removal
        )
    }
    
    var body: some View {
        ZStack {
            if let (currentRoute, uuid) = stackModel.routeStack.last {
                routeProvider(currentRoute)
                    .id(uuid)
                    .transition(dynamicTransition())
            } else {
                rootView
                    .transition(dynamicTransition())
            }
        }
        .onGeometryChange(for: CGSize.self) {
            $0.size
        } action: { newSize in
            containerSize = newSize
        }
    }
}

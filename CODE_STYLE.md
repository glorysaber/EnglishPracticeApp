# English Practice - Code Style Guide

## Development Guidelines for Team Members and AI Assistants

---

## 📋 Table of Contents

- [Swift Language Version](#swift-language-version)
- [Logging Standards](#logging-standards)
- [File Organization](#file-organization)

---

## 🎯 Swift Language Version

Swift 6.x

---

## 📝 Logging Standards

### ✅ Consistent Logging Pattern

```swift
// ✅ Use structured logging with consistent categories
private extension Logger {
    static func subsystem(_ category: String) -> Logger {
        Logger(subsystem: "EnglishPractice.\(category)", category: category)
    }

    // Specific loggers for different purposes
    static var dataStorage = Logger.subsystem("DataStorage")
    static var sessionStorage = Logger.subsystem("SessionStorage")
    static var network = Logger.subsystem("Network")
}

// ✅ Log with appropriate levels and context
private let logger = Logger.sessionStorage

func performOperation() {
    logger.info("Starting operation with params: \(operationParams)")

    do {
        try await executeOperation()

        logger.log("Operation completed successfully")
    } catch {
        logger.error("Operation failed: \(error.localizedDescription)")

        // Log structured error details
        logger.debug("Error context: \(error._domain), code: \(error._code)")

        throw error
    }
}
```

---

## 📁 File Organization

### ✅ Feature-Based Architecture

```
EnglishPractice/
├── Features/          # Feature modules
│   ├── SessionManagement/
│   │   ├── Models/
│   │   ├── Services/
│   │   └── Views/
│   └── ProgressionTracking/
├── Shared/            # Cross-cutting concerns
│   ├── Utility/
│   │   ├── Logging.swift
│   │   ├── BGTaskManager.swift
│   │   └── Constants.swift
│   └── SwiftUI/
│       ├── ViewModifiers/
│       └── Components/
└── Resources/         # Assets and configuration
```

### ✅ File Naming Conventions

```swift
// ✅ Consistent naming patterns
WordProgression.swift          // Domain model
ProgressionTracker.swift       // Service layer
WordAttemptViewModel.swift      // MVVM pattern
BGTaskManager.swift            // Utility effect
```

---


### 🚀 Best Practices Reference

```swift
// Quick references for common patterns

// ✅ Async Function Declaration instead of detatched Tasks
nonisolated func performAsyncWork(params: Params) async throws -> Result

// ✅ Stored Task Handle
private var backgroundTask: Task<Void, Error>?

// ✅ Task Execution Pattern
backgroundTask?.cancel()
backgroundTask = Task(priority: .utility) { [weak self] in
    do {
        try await operation()
    } catch {
        await logger.error("Operation failed: \(error)")
    }
}

// ✅ Structured Concurrency Pattern
try await withThrowingTaskGroup(of: Result.self) { group in
    group.addTask { try await operation1() }
    group.addTask { try await operation2() }
    // Process results...
}
```

// ❎ @unchecked Sendable
Never use unchecked Sendable.
```

---

*This style guide will be updated as the project evolves. Always consult with team lead for clarification on patterns not covered here.*

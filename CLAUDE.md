# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Running
```bash
# Open project in Xcode
open Nova.xcodeproj

# Build and run from command line (if xcodebuild is needed)
xcodebuild -project Nova.xcodeproj -scheme Nova -destination 'platform=macOS' build
```

### Testing
```bash
# Run all tests from command line
xcodebuild test -project Nova.xcodeproj -scheme Nova -destination 'platform=macOS'

# Run specific test target
xcodebuild test -project Nova.xcodeproj -scheme Nova -destination 'platform=macOS' -only-testing:NovaTests
xcodebuild test -project Nova.xcodeproj -scheme Nova -destination 'platform=macOS' -only-testing:NovaUITests
```

## Architecture Overview

### Core Application Structure
Nova is a SwiftUI-based macOS application designed to be an AI-powered background assistant. The architecture follows a clean separation of concerns:

- **`NovaApp.swift`**: Main application entry point using SwiftUI's App protocol with Core Data integration
- **`ContentView.swift`**: Primary UI layer currently implementing a basic navigation-based interface with Core Data CRUD operations
- **`Persistence.swift`**: Core Data stack management with singleton pattern and preview support

### Data Layer
The app uses Core Data for persistence with a simple but extensible model:
- **Entity**: `Item` with timestamp attribute (placeholder for future conversation/memory entities)
- **Architecture**: Singleton `PersistenceController.shared` for production, separate in-memory store for previews
- **Error Handling**: Currently uses `fatalError()` for development - should be replaced with proper error handling for production

### Planned Architecture (from README)
The current codebase is a foundation for a much more complex application that will include:
- **Dual AI Integration**: OpenAI cloud services + Ollama local processing
- **System Integration**: Screen capture, clipboard monitoring, voice recognition
- **Adaptive UI**: Minimal floating window that expands to full conversational interface
- **Memory Systems**: User preferences, conversation history, activity tracking

## Key Implementation Notes

### Core Data Usage Pattern
The app follows standard Core Data patterns but with SwiftUI integration:
```swift
@Environment(\.managedObjectContext) private var viewContext
@FetchRequest private var items: FetchedResults<Item>
```

### SwiftUI Preview Configuration
Preview support is properly configured with sample data generation in `PersistenceController.preview`.

### Project Configuration
- **Target**: macOS 15.5 (Sequoia)
- **Swift**: 5.0
- **Testing**: Uses Swift Testing framework for unit tests, XCTest for UI tests
- **Sandboxing**: Minimal entitlements currently (will need expansion for planned features)

### Required Future Entitlements
Based on the planned features, the app will need:
- Microphone access for voice input
- Screen recording for screen analysis
- Accessibility permissions for system integration
- Network access for AI APIs

## Development Workflow

### Current State
This is a fresh codebase with basic SwiftUI + Core Data template implementation. The actual AI assistant features described in the README are not yet implemented.

### Next Implementation Steps
1. Replace placeholder Core Data model with conversation/memory entities
2. Implement minimal floating window UI
3. Add Speech framework integration for voice recognition
4. Integrate AI services (OpenAI/Ollama)
5. Add system permission handling
6. Implement screen capture and clipboard monitoring

### Testing Strategy
- Unit tests use Swift Testing framework (modern Apple testing)
- UI tests include launch performance measurement and screenshot capture
- Preview data generation supports SwiftUI development workflow
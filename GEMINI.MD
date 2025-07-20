# GEMINI.MD: AI Collaboration Guide

This document provides essential context for AI models interacting with this project. Adhering to these guidelines ensures consistency, maintainability, and high code quality in all AI-generated contributions.

---

## 1. Project Overview & Purpose

- **Primary Goal:**
  This project, "Nova," is a native SwiftUI application for macOS/iOS that serves as a chat client for multiple AI models. It integrates with various backend services, including OpenAI, Anthropic (Claude), Mistral, and local models via Ollama. It also includes voice-to-text functionality using Whisper.

- **Business Domain:**
  Developer Tools / AI-Powered Applications. It's a consumer-facing application for users who want to interact with different AI models from a single, unified interface.

---

## 2. Core Technologies & Stack

- **Languages:**
  - Swift (Primary)
  - Python (for utility/conversion scripts, e.g., `Resources/WakewordModels/conversion.py`)

- **Frameworks & Runtimes:**
  - SwiftUI (for the user interface)
  - CoreData (for local data persistence, e.g., chat history)
  - ONNX (for running local wakeword models)

- **Databases:**
  - SQLite (as the backing store for CoreData)

- **Key Libraries/Dependencies:**
  While not explicitly listed, the project likely uses:
  - A networking library (like Alamofire or URLSession) for API calls to AI services.
  - A library for ONNX model inference.

- **Package Manager(s):**
  - Swift Package Manager (inferred as the standard for modern Xcode projects).

---

## 3. Architectural Patterns

- **Overall Architecture:**
  - **MVVM (Model-View-ViewModel):** The separation of `Views/`, `ViewModels/`, and `Models/` directories strongly indicates the use of the MVVM pattern.
  - **Service-Oriented:** The `Backend/Services` directory suggests a service layer that encapsulates business logic and data access, which are then used by the ViewModels.

- **Directory Structure Philosophy:**
  - `Nova/`: Contains all the source code for the application.
  - `Nova/Backend`: Manages all interactions with external and local AI services.
    - `Clients`: Low-level API clients for each specific AI provider.
    - `Services`: Higher-level services that orchestrate the use of clients.
    - `Models`: Data structures for API requests and responses.
  - `Nova/Views`: SwiftUI views for the UI.
  - `Nova/ViewModels`: ViewModels that provide data and logic to the Views.
  - `Nova/Models`: Core application models (e.g., `ChatMessage`).
  - `Nova/NovaMarkdown`: A custom module for parsing and rendering Markdown.
  - `Nova/Resources`: Contains assets and compiled machine learning models (`.mlmodelc`, `.onnx`).
  - `NovaTests/`, `NovaUITests/`: Contains unit and UI tests, respectively.
  - `Nova.xcodeproj`: The Xcode project file.

---

## 4. Coding Conventions & Style Guide

- **Formatting:**
  - Standard Swift style as enforced by Xcode. Adhere to the existing format.

- **Naming Conventions:**
  - **Types & Files:** `PascalCase` (e.g., `ChatViewModel`, `ContentView`).
  - **Variables & Functions:** `camelCase` (e.g., `chatMessages`, `sendMessage()`).

- **API Design:**
  - The application consumes external REST APIs. Internal services should be designed to be clean and reusable.

- **Error Handling:**
  - Use Swift's standard `Result` type and `do-try-catch` blocks for handling errors, particularly for network operations and data parsing.

---

## 5. Key Files & Entrypoints

- **Main Entrypoint(s):**
  - `Nova/NovaApp.swift`: The main entry point for the SwiftUI application life cycle.
- **Configuration:**
  - `Nova/Configuration/AppConfig.swift`: Likely holds global application configuration.
  - `Nova/Backend/Configuration/`: Contains provider-specific configurations (e.g., `OllamaConfiguration.swift`).
- **CI/CD Pipeline:**
  - No CI/CD pipeline configuration files (e.g., `.github/workflows`) are visible in the project structure.

---

## 6. Development & Testing Workflow

### Building and Running

```bash
# Open project in Xcode
open Nova.xcodeproj

# Build and run from command line
xcodebuild -project Nova.xcodeproj -scheme Nova -destination 'platform=macOS' build
```

### Testing

```bash
# Run all tests from command line
xcodebuild test -project Nova.xcodeproj -scheme Nova -destination 'platform=macOS'

# Run a specific test target
xcodebuild test -project Nova.xcodeproj -scheme Nova -destination 'platform=macOS' -only-testing:NovaTests
xcodebuild test -project Nova.xcodeproj -scheme Nova -destination 'platform=macOS' -only-testing:NovaUITests
```

---

## 7. Specific Instructions for AI Collaboration

- **Contribution Guidelines:**
  - All new features should follow the existing MVVM and Service-Oriented architecture.
  - UI components should be implemented in SwiftUI.
  - New AI provider integrations should be added by creating a new `Client` and `Service` in the `Backend` directory, following the existing patterns.

- **Security:**
  - **Never hardcode secrets.** API keys and other sensitive information must not be stored in the source code. Use a secure method for managing secrets (e.g., Xcode configurations, environment variables).

- **Dependencies:**
  - If adding a new dependency, use Swift Package Manager. Update the project file accordingly.

- **Commit Messages:**
  - Follow Conventional Commits style (e.g., `feat:`, `fix:`, `docs:`, `refactor:`). This helps maintain a clear and understandable commit history.

---

## 8. Inferred Standards & Confidence Levels

| Section               | Inferred From                    | Confidence     | Notes                                                      |
|-----------------------|----------------------------------|----------------|------------------------------------------------------------|
| Project Goal          | File names, directory structure  | High           | Clearly a multi-provider AI chat app.                      |
| Core Technologies     | File extensions, project type    | High           | SwiftUI, Swift, and CoreData are evident.                  |
| Architecture          | Directory structure (`ViewModels`) | High           | Classic MVVM structure for a SwiftUI app.                  |
| Testing Framework     | `NovaTests` folder, Xcode standard | High           | XCTest is the default for Xcode projects.                  |
| Package Manager       | Modern Xcode project convention  | Medium         | Swift Package Manager is the likely choice.                |

---

## ✅ Recommended Next Steps for Maintainers

1. Review and confirm the inferred details, especially the package manager and any key libraries not visible in the file structure.
2. Fill out any blanks, such as specific Swift version or deployment targets.
3. Keep **GEMINI.MD** updated with major changes (new tech, architectural shifts).

---

##  Usage Notes for AI Models

- Before generating code or refactoring, review this file to align with architecture, dependencies, conventions, and deployment flows.
- Follow section 7’s instructions closely—especially regarding security and architectural patterns.
- When in doubt, replicate existing patterns from the codebase rather than inventing new ones.

**Important**: Whenever writing code, run with code-reasoning mcp.

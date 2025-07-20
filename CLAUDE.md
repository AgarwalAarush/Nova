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
Nova is a SwiftUI-based macOS application designed as an AI-powered chat assistant with comprehensive system automation capabilities. The architecture follows a clean separation of concerns with a sophisticated multi-layer design:

- **`NovaApp.swift`**: Main application entry point with SwiftUI App protocol, integrating Core Data, WhisperService, AIServiceRouter, and SystemAutomationService
- **`ContentView.swift`**: Primary UI controller that bridges environment objects to ChatView
- **`ChatView.swift`**: Main chat interface with integrated voice input, settings access, and automation controls
- **`CompactVoiceView.swift`**: Minimal voice-focused interface for streamlined interactions
- **`Persistence.swift`**: Core Data stack management (currently using placeholder Item entity)

### AI Integration Layer
The app implements a comprehensive AI service abstraction:

#### AIServiceRouter (`Backend/Services/AIServiceRouter.swift`)
- **Multi-Provider Support**: Manages 4 AI providers (Ollama, OpenAI, Claude, Mistral)
- **Automatic Fallback**: Intelligent provider switching with configurable fallback order
- **Streaming Support**: Real-time streaming responses across all providers
- **Connection Management**: Health monitoring and error handling

#### Supported AI Providers
1. **Ollama** (`Backend/Services/OllamaService.swift`): Local AI with models like llama3.2, gemma3, qwen2.5
2. **OpenAI** (`Backend/Services/OpenAIService.swift`): GPT models including gpt-4o-mini
3. **Claude** (`Backend/Services/ClaudeService.swift`): Anthropic's Claude models
4. **Mistral** (`Backend/Services/MistralService.swift`): Mistral AI models

### Speech Recognition System
Advanced Whisper-based speech-to-text integration:

#### WhisperService (`Backend/Services/WhisperService.swift`)
- **Model Management**: Multiple Whisper model sizes (tiny.en through large)
- **Background Loading**: Asynchronous model loading with progress tracking
- **Audio Processing**: Complete audio pipeline from recording to transcription
- **Performance Optimization**: Configurable model sizes and background processing

#### AudioRecorderService (`Backend/Services/AudioRecorderService.swift`)
- **Native Recording**: AVAudioEngine-based audio capture
- **Permission Handling**: Microphone permission management
- **Format Conversion**: Automatic audio format conversion for Whisper

### System Automation Layer
Nova includes a comprehensive macOS automation system with tool-based execution:

#### SystemAutomationService (`Backend/Services/SystemAutomationService.swift`)
- **Protocol Definition**: Unified interface for all automation capabilities across macOS
- **Permission Management**: Comprehensive handling of accessibility, screen recording, and system events permissions
- **Multi-Domain Support**: Display, application, window, system, screenshot, clipboard, and memory management

#### ToolCallExecutor (`Backend/Services/ToolCallExecutor.swift`)
- **Tool Execution**: Orchestrates execution of automation tools with context sharing
- **Context Management**: Maintains state and data between tool calls for complex workflows
- **Error Handling**: Robust error recovery and execution result tracking
- **AI Integration**: Seamless integration with AI services for intelligent automation requests

#### Automation Services
1. **ScreenshotService** (`Backend/Services/ScreenshotService.swift`): Advanced screen capture with window-specific targeting
2. **ClipboardService** (`Backend/Services/ClipboardService.swift`): Comprehensive clipboard management with metadata support
3. **MacOSAutomationService** (`Backend/Services/MacOSAutomationService.swift`): Core system automation implementation

#### Tool Schema (`Resources/tools.json`)
- **Structured Tool Definitions**: JSON schema defining 50+ automation tools across 7 categories
- **Type Safety**: Complete parameter validation and type definitions
- **AI Consumption**: Optimized for AI model tool calling with clear specifications

### AI Tool Calling System
Advanced AI interaction framework for intelligent automation:

#### PromptRouterService (`Backend/Services/PromptRouterService.swift`)
- **Intelligent Routing**: Converts natural language requests into structured tool calls
- **Multi-Provider Support**: Works across all AI providers with model compatibility checking
- **Context Enhancement**: Automatically enriches prompts with available system context
- **JSON Parsing**: Robust parsing of AI responses into executable tool sequences

#### Tool Call Architecture
- **Structured Execution**: Tool calls with parameters, validation, and error handling
- **Context Sharing**: Data persistence between tool calls for complex workflows
- **Result Aggregation**: Comprehensive result summary and error reporting

### Enhanced Security System
Secure credential management and privacy protection:

#### KeychainService (`Services/KeychainService.swift`)
- **Secure Storage**: macOS Keychain integration for API key storage
- **Migration Support**: Automatic migration from plain text to encrypted storage
- **Multi-Provider**: Secure storage for all AI provider credentials
- **Access Control**: Device-specific encryption with proper access controls

### Custom Markdown Engine
NovaMarkdown - A custom SwiftUI-native markdown renderer:

#### Core Components (`NovaMarkdown/`)
- **Parser** (`Parser/MarkdownParser.swift`): Efficient regex-based markdown parsing
- **AST** (`Core/Markup.swift`): Immutable document tree structure
- **Renderer** (`SwiftUI/SwiftUIRenderer.swift`): Visitor pattern for SwiftUI view generation
- **Configuration** (`SwiftUI/RenderConfiguration.swift`): Styling and layout options

#### Features
- Complete markdown support (headings, emphasis, code blocks, lists, tables, etc.)
- Chat-optimized styling with AppColors/AppFonts integration
- Performance-optimized for real-time rendering
- Thread-safe immutable data structures

### Configuration System
Centralized configuration management:

#### AppConfig (`Configuration/AppConfig.swift`)
- **JSON Persistence**: Configuration saved to Documents directory
- **API Key Management**: Secure storage for cloud provider credentials
- **Multi-Provider Settings**: Provider selection and fallback configuration
- **Audio Configuration**: Whisper model selection and audio parameters
- **UI Preferences**: Interface and performance options

### UI Architecture
Modern SwiftUI-based interface with custom theming:

#### View Components
- **ChatView**: Main chat interface with toolbar, settings integration, and automation controls
- **CompactVoiceView**: Minimal voice-focused interface for streamlined interactions
- **MessageListView**: Scrollable message display with markdown rendering
- **InputBarView**: Text input with voice recording capabilities
- **SettingsView**: Comprehensive settings interface with provider configuration
- **ModelSelectorView**: Enhanced model selection with provider synchronization

#### ViewModels
- **ChatViewModel**: Chat state management with voice transcription integration
- **SettingsViewModel**: Configuration management with real-time updates

#### Theming (`Theme/`)
- **AppColors**: Dark theme color scheme with markdown-specific colors
- **AppFonts**: Custom typography using Clash Grotesk variable font

### Data Layer
Core Data integration (currently minimal):
- **Entity**: `Item` with timestamp (placeholder for future conversation storage)
- **Pattern**: Environment-based context injection with preview support
- **Future**: Will be expanded for conversation history and user preferences

## Key Implementation Patterns

### Service Architecture
The app uses a clean service-oriented architecture:

```swift
// AI Service abstraction
protocol AIService {
    func generateResponse(for message: String) async throws -> String
    func generateStreamingResponse(for message: String) -> AsyncThrowingStream<String, Error>
}

// Audio transcription abstraction
protocol AudioTranscriptionService {
    func transcribeAudio(input: WhisperAudioInput, request: WhisperTranscriptionRequest) async throws -> WhisperTranscriptionResponse
}
```

### Environment Object Pattern
Services are injected via SwiftUI environment:

```swift
@EnvironmentObject var whisperService: WhisperService
@EnvironmentObject var aiServiceRouter: AIServiceRouter
```

### Async/Await Integration
Modern Swift concurrency throughout:
- Streaming AI responses with AsyncThrowingStream
- Background audio processing
- Concurrent model loading

### Error Handling
Comprehensive error handling with custom error types:
- `AIServiceError`: AI-specific errors with fallback logic
- `WhisperError`: Audio processing errors
- `AudioRecorderError`: Recording permission and hardware errors

## Project Configuration

### Target Requirements
- **Platform**: macOS 15.5+ (Sequoia)
- **Swift**: 6.0
- **Deployment**: macOS 15.5
- **Architecture**: Apple Silicon + Intel

### Entitlements (`Nova.entitlements`)
Currently configured entitlements:
- Microphone access for voice input
- Network client for AI API access
- Audio input for speech recognition

### Dependencies
The app includes:
- **Custom Markdown Engine**: NovaMarkdown (built-in)
- **Whisper Models**: Pre-bundled tiny.en and small Core ML models
- **Custom Fonts**: Clash Grotesk variable font
- **Wake Word Models**: ONNX models (embedding_model.onnx, jarvis.onnx, melspectrogram.onnx) for voice activation
- **Automation Tools Schema**: Comprehensive JSON definition of system automation capabilities
- **Security Framework**: macOS Keychain integration for secure credential storage

### Asset Management
- **App Icons**: Multiple sizes in AppIcon.appiconset
- **Whisper Models**: Pre-compiled Core ML models in Resources/Models/
- **Fonts**: Custom typography assets
- **Colors**: Programmatic color definitions

## Development Workflow

### Current Implementation Status
**Fully Implemented:**
- ✅ Multi-provider AI integration with streaming support
- ✅ Advanced speech recognition with Whisper
- ✅ Custom markdown rendering engine
- ✅ Comprehensive settings system
- ✅ Voice dictation in chat interface
- ✅ Dark theme with custom typography
- ✅ Configuration persistence
- ✅ **System automation suite** with 50+ automation tools
- ✅ **AI tool calling system** with intelligent prompt routing
- ✅ **Secure credential storage** with Keychain integration
- ✅ **Screen capture and clipboard management**
- ✅ **Compact voice interface mode**
- ✅ **Advanced permission management** for automation features

**In Progress/Future:**
- 🔄 Conversation history persistence
- 🔄 Wake word detection (models prepared)
- 🔄 Floating window mode
- 🔄 Background processing optimization
- 🔄 Advanced window management automation
- 🔄 Voice activation pipeline

### Implementation Patterns

#### Adding New AI Providers
1. Create client in `Backend/Clients/`
2. Implement service in `Backend/Services/`
3. Add models in `Backend/Models/`
4. Update `AIProvider` enum in `AppConfig`
5. Configure in `AIServiceRouter`

#### UI Component Development
1. Follow AppColors/AppFonts theming
2. Use environment object injection
3. Implement proper error states
4. Add loading indicators where appropriate

#### Audio Feature Development
1. Extend `AudioTranscriptionService` protocol
2. Implement in `WhisperService`
3. Update UI in `InputBarView`
4. Add configuration in `AppConfig`

#### System Automation Development
1. Define new tool in `tools.json` schema
2. Implement tool execution in `ToolCallExecutor`
3. Add service method in `SystemAutomationService`
4. Update `AutomationModels.swift` for data structures
5. Handle permissions in automation service implementation

### Testing Strategy
- **Unit Tests**: Service layer testing with mock implementations
- **UI Tests**: SwiftUI interface testing with XCTest
- **Integration Tests**: End-to-end AI provider testing
- **Preview Support**: Comprehensive SwiftUI preview configuration

### Performance Considerations
- **Model Loading**: Background Whisper model loading
- **Streaming**: Efficient real-time message rendering
- **Memory**: Lazy loading and proper cleanup
- **Network**: Intelligent fallback and error recovery

## Key Files Reference

### Core Application
- `NovaApp.swift` - Application entry point and service injection
- `ContentView.swift` - Main view controller
- `ChatView.swift` - Primary chat interface

### AI Integration
- `Backend/Services/AIServiceRouter.swift` - Multi-provider AI management
- `Backend/Services/WhisperService.swift` - Speech recognition service
- `Backend/Services/PromptRouterService.swift` - AI tool calling and prompt routing
- `Configuration/AppConfig.swift` - Centralized configuration

### System Automation
- `Backend/Services/SystemAutomationService.swift` - Automation protocol definition
- `Backend/Services/ToolCallExecutor.swift` - Tool execution orchestration
- `Backend/Services/MacOSAutomationService.swift` - Core automation implementation
- `Backend/Services/ScreenshotService.swift` - Screen capture functionality
- `Backend/Services/ClipboardService.swift` - Clipboard management
- `Backend/Models/AutomationModels.swift` - Automation data structures
- `Resources/tools.json` - Tool schema definitions

### Security & Storage
- `Services/KeychainService.swift` - Secure credential storage
- `Configuration/AppConfig.swift` - Configuration with Keychain integration

### UI Components
- `Views/ChatView.swift` - Main chat interface with automation
- `Views/CompactVoiceView.swift` - Minimal voice interface
- `Views/Settings/SettingsView.swift` - Configuration interface
- `Views/Components/ModelSelectorView.swift` - Enhanced model selection
- `ViewModels/ChatViewModel.swift` - Chat state management

### Custom Libraries
- `NovaMarkdown/` - Complete markdown rendering engine
- `Theme/` - Centralized theming system
- `Backend/` - Service architecture, AI clients, and automation services

This architecture represents a mature, production-ready AI chat application with sophisticated multi-provider support, advanced speech recognition, comprehensive system automation capabilities, and a custom markdown engine optimized for chat interactions. The system now supports intelligent tool calling, secure credential management, and extensive macOS system integration for a complete AI assistant experience.
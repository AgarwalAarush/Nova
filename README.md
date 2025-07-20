
<div align="center">

<img src="Nova/Assets.xcassets/AppIcon.appiconset/AppIcon-4%20(dragged).png" alt="Nova App Icon" width="128" height="128">

<h1>Nova AI Assistant</h1>

*Nova - Your intelligent macOS AI assistant with comprehensive system automation*

<!-- Demo Video Section -->
## 🎬 Demo Video
> *Coming Soon - Demo video showcasing Nova's AI-powered automation and voice interaction capabilities*

</div>

---

## Overview

Nova is a sophisticated macOS AI assistant that combines advanced AI capabilities with comprehensive system automation. Built with SwiftUI and leveraging cutting-edge AI technologies, Nova provides intelligent voice interaction, multi-provider AI routing, and powerful macOS automation through 50+ specialized tools.

## ✨ Key Features

### 🤖 Advanced Multi-Provider AI Integration
- **Four AI Providers**: Ollama (local), OpenAI, Claude (Anthropic), and Mistral
- **Intelligent Routing**: Automatic provider fallback with intelligent prompt routing
- **Streaming Support**: Real-time streaming responses across all providers
- **Model Flexibility**: Support for multiple models per provider with power rankings

### 🎤 Professional Speech Recognition
- **Whisper Integration**: Advanced speech-to-text using multiple Whisper model sizes
- **Background Processing**: Asynchronous model loading with progress tracking
- **Audio Pipeline**: Complete audio processing from recording to transcription
- **Model Management**: Configurable model sizes (tiny.en through large)

### 🛠 Comprehensive System Automation
- **50+ Automation Tools**: Organized across 7 categories (display, application, window, system, screenshot, clipboard, memory)
- **AI Tool Calling**: Intelligent conversion of natural language to structured tool calls
- **Context Sharing**: Data persistence between tool calls for complex workflows
- **Permission Management**: Advanced handling of accessibility, screen recording, and system events

### 🖥 Adaptive Interface Modes
- **ChatView**: Full conversational interface with markdown rendering
- **CompactVoiceView**: Minimal voice-focused interface for streamlined interactions
- **Markdown Engine**: Custom NovaMarkdown renderer optimized for AI conversations
- **Dark Theme**: Custom typography using Clash Grotesk variable font

### 🔒 Enterprise-Grade Security
- **Keychain Integration**: Secure credential storage with automatic migration
- **Multi-Provider Security**: Secure API key management for all AI providers
- **Device-Specific Encryption**: Proper access controls and data protection
- **Privacy-First**: Local processing options with Ollama integration

## 🏗 Architecture

### Core Application Structure
Nova implements a sophisticated multi-layer architecture with clean separation of concerns:

```
Nova/
├── NovaApp.swift                    # Main application entry point
├── ContentView.swift                # Primary UI controller
├── ChatView.swift                   # Main chat interface
├── CompactVoiceView.swift          # Minimal voice interface
└── Backend/
    ├── Services/
    │   ├── AIServiceRouter.swift    # Multi-provider AI management
    │   ├── WhisperService.swift     # Speech recognition service
    │   ├── PromptRouterService.swift # AI tool calling & routing
    │   ├── SystemAutomationService.swift # Automation protocol
    │   ├── ToolCallExecutor.swift   # Tool execution orchestration
    │   ├── MacOSAutomationService.swift # Core automation implementation
    │   ├── ScreenshotService.swift  # Screen capture functionality
    │   └── ClipboardService.swift   # Clipboard management
    ├── Clients/                     # AI provider clients
    │   ├── OllamaClient.swift
    │   ├── OpenAIClient.swift
    │   ├── ClaudeClient.swift
    │   ├── MistralClient.swift
    │   └── WhisperClient.swift
    └── Models/                      # Data structures & API models
├── NovaMarkdown/                    # Custom markdown rendering engine
│   ├── Core/                       # AST and visitor patterns
│   ├── Parser/                     # Efficient regex-based parsing
│   └── SwiftUI/                    # SwiftUI view generation
├── Configuration/
│   └── AppConfig.swift             # Centralized configuration
├── Services/
│   └── KeychainService.swift       # Secure credential storage
├── Theme/                          # Custom theming system
│   ├── AppColors.swift
│   └── AppFonts.swift
└── Resources/
    ├── tools.json                  # Comprehensive tool schema (50+ tools)
    ├── Models/                     # Pre-bundled Whisper models
    └── WakewordModels/            # ONNX models for voice activation
```

### Service Architecture Patterns
- **Protocol-Based Design**: Clean abstractions for AI services and automation
- **Environment Object Injection**: SwiftUI-native dependency injection
- **Async/Await Integration**: Modern Swift concurrency throughout
- **Streaming Architecture**: Real-time data processing with AsyncThrowingStream

## 🔧 System Requirements

### macOS Version
- **macOS 15.5+ (Sequoia)** required
- Apple Silicon and Intel support

### Required Permissions
- **Microphone Access**: For advanced voice input and recognition
- **Accessibility**: For comprehensive system automation
- **Screen Recording**: For screen capture and analysis
- **Network Access**: For cloud AI services

### Dependencies & Tools
- Xcode 15.0+
- Swift 6.0
- API keys for cloud providers (OpenAI, Claude, Mistral)
- Ollama (optional, for local AI processing)

## 🚀 Installation & Setup

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/nova.git
cd Nova
```

### 2. Open in Xcode
```bash
open Nova.xcodeproj
```

### 3. Configure AI Providers
Launch Nova and use the built-in settings interface to securely configure:
- **OpenAI**: API key for GPT models
- **Claude**: Anthropic API key for Claude models
- **Mistral**: API key for Mistral models
- **Ollama**: Local installation (optional)

### 4. Grant System Permissions
Nova will request necessary permissions on first launch:
- Microphone access for voice features
- Accessibility for system automation
- Screen recording for screen capture tools

### 5. Build and Run
Select your target and build (⌘+R). All credentials are securely stored in macOS Keychain.

## 🎯 Usage

### Voice Interaction
- Launch Nova and click the microphone button or use voice activation
- Speak naturally - Nova converts speech to text using advanced Whisper models
- Responses are intelligently routed through the best available AI provider
- Switch between ChatView (full interface) and CompactVoiceView (minimal)

### System Automation
Nova understands natural language requests for system tasks:
- *"Take a screenshot of the current window"*
- *"Copy the clipboard content and summarize it"*
- *"Open System Preferences and navigate to Display settings"*
- *"Get information about running applications"*

### AI Provider Management
- **Automatic Fallback**: If primary provider fails, Nova intelligently switches
- **Model Selection**: Choose from available models per provider
- **Performance Optimization**: Models are ranked by capability and speed
- **Local Processing**: Use Ollama for privacy-sensitive tasks

## 🛣 Next Steps & Roadmap

### 🔊 Text-to-Speech Integration
- **Cartesia Integration**: High-quality AI-generated speech synthesis
- **ElevenLabs Support**: Premium voice cloning and natural speech
- **Local TTS**: On-device speech synthesis for privacy
- **Voice Customization**: Multiple voice options and speech parameters

### 🖥 Enhanced macOS Integration
- **Improved mac-use**: Advanced macOS automation with window management
- **App Control**: Deep integration with native macOS applications
- **Workflow Automation**: Multi-step task automation with conditional logic
- **System Monitoring**: Intelligent system state awareness and optimization

### 📌 Pinnable Voice Interface
- **Top Window Priority**: Always-on-top compact voice interface
- **Global Hotkeys**: System-wide voice activation shortcuts
- **Floating Window**: Draggable, resizable voice interface
- **Quick Actions**: Rapid access to common automation tasks

### 🔮 Advanced Features (Future)
- **Wake Word Detection**: "Hey Nova" activation (models prepared)
- **Conversation History**: Persistent chat history with search
- **Memory System**: Long-term user preference learning
- **Custom Workflows**: User-defined automation sequences
- **Plugin Architecture**: Third-party automation tool integration

## 🧪 Development

### Building from Source
```bash
# Build project
xcodebuild -project Nova.xcodeproj -scheme Nova -destination 'platform=macOS' build

# Run tests
xcodebuild test -project Nova.xcodeproj -scheme Nova -destination 'platform=macOS'
```

### Testing
- **Unit Tests**: Service layer with mock implementations
- **UI Tests**: SwiftUI interface automation with XCTest
- **Integration Tests**: End-to-end AI provider testing

### Contributing
1. Fork the repository
2. Create feature branch: `git checkout -b feature/your-feature`
3. Follow existing patterns and architecture
4. Add tests for new functionality
5. Submit pull request

## 🔒 Privacy & Security

- **Local-First**: Ollama integration for on-device AI processing
- **Encrypted Storage**: All credentials secured in macOS Keychain
- **Minimal Data**: Only necessary information collected and stored
- **User Control**: Complete control over data and provider selection
- **Secure Communication**: Encrypted API calls to external services

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **OpenAI** for GPT models and API
- **Anthropic** for Claude AI capabilities
- **Mistral AI** for open-source AI models
- **Ollama** for local AI processing
- **Apple** for excellent SwiftUI and macOS frameworks
- **Open Source Community** for inspiration and tools

---

**Built with ❤️ using SwiftUI • Powered by Multi-Provider AI • Enhanced with Comprehensive Automation**

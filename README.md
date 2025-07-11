# Nova AI Assistant

An intelligent background assistant for macOS that provides seamless AI-powered help through voice interaction and contextual awareness.

## Overview

Nova is a macOS application designed to be your always-available AI companion. It runs quietly in the background, accessible through a minimal interface in the upper-right corner of your screen. Nova can see your screen, hear your voice, access your clipboard, and maintain context about your activities to provide intelligent, personalized assistance.

## Key Features

### 🎤 Voice-First Interaction
- Always-listening capability with visual speech indicator
- Natural conversation flow with persistent memory
- Toggle between listening modes

### 🧠 Dual AI Engine Support
- **OpenAI Integration**: Cloud-based processing for complex queries
- **Ollama Support**: Local AI processing for privacy-sensitive tasks
- Intelligent routing based on query complexity and user preferences

### 📱 Adaptive Interface
- **Minimal Mode**: Tiny white window with AI speech animation
- **Expanded Mode**: Full conversational interface with markdown rendering
- Automatic expansion for complex responses
- Manual toggle between modes

### 🔍 System Integration
- Screen capture and analysis
- Clipboard monitoring and management
- Audio input processing
- System activity awareness

### 💾 Intelligent Memory
- **User Memory**: Persistent understanding of preferences and habits
- **Conversation Memory**: Context-aware dialogue history
- **Activity Memory**: Knowledge of recent user actions
- **Chat History**: Searchable conversation archive

## Architecture

### Core Technologies
- **SwiftUI**: Modern, declarative UI framework
- **Core Data**: Local data persistence and memory management
- **Speech Framework**: Voice recognition and processing
- **Screen Capture Kit**: Screen content analysis
- **Combine**: Reactive programming for real-time updates

### Project Structure
```
Nova/
├── Nova/
│   ├── NovaApp.swift          # Main app entry point
│   ├── ContentView.swift      # Primary UI components
│   ├── Persistence.swift      # Core Data stack
│   ├── Models/               # Data models and AI integrations
│   ├── Views/                # UI components and layouts
│   ├── Services/             # AI, audio, and system services
│   └── Utils/                # Helper functions and extensions
├── NovaTests/                # Unit tests
└── NovaUITests/              # UI automation tests
```

## System Requirements

### macOS Version
- macOS 13.0 (Ventura) or later

### Required Permissions
- **Microphone Access**: For voice input
- **Screen Recording**: For screen analysis
- **Accessibility**: For system integration
- **Network Access**: For cloud AI services

### Dependencies
- Xcode 15.0+
- Swift 5.9+
- OpenAI API key (for cloud features)
- Ollama installation (for local AI)

## Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/nova.git
cd nova
```

### 2. Configure AI Services

#### OpenAI Setup
1. Obtain an API key from [OpenAI](https://platform.openai.com/api-keys)
2. Add your key to the app's configuration:
   ```swift
   // In Config.swift
   static let openAIKey = "your-api-key-here"
   ```

#### Ollama Setup (Optional)
1. Install Ollama: `brew install ollama`
2. Download a local model: `ollama pull llama2`
3. Ensure Ollama service is running: `ollama serve`

### 3. Build and Run
1. Open `Nova.xcodeproj` in Xcode
2. Select your target device
3. Grant required permissions when prompted
4. Build and run the project (⌘+R)

## Usage

### Getting Started
1. Launch Nova from Applications
2. Grant requested system permissions
3. The minimalist interface appears in the upper-right corner
4. Click the microphone or speak to begin interaction

### Interface Modes

#### Minimal Mode
- Small white window with AI activity indicator
- Always visible but unobtrusive
- Click to activate voice input
- Automatic expansion for complex responses

#### Expanded Mode
- Full conversational interface
- Markdown-formatted responses
- Text input capability
- Conversation history access
- Easy minimize button to return to minimal mode

### Voice Commands
- **"Hey Nova"**: Wake phrase for activation
- **"Expand"**: Switch to expanded interface
- **"Minimize"**: Return to minimal mode
- **"Search conversations"**: Access chat history

## Features Roadmap

### Phase 1: Core Foundation ✅
- [x] Basic SwiftUI interface
- [x] Core Data persistence setup
- [ ] Minimal window implementation
- [ ] Basic voice recognition

### Phase 2: AI Integration
- [ ] OpenAI API integration
- [ ] Ollama local AI support
- [ ] Response complexity detection
- [ ] Automatic interface adaptation

### Phase 3: System Integration
- [ ] Screen capture functionality
- [ ] Clipboard monitoring
- [ ] Activity tracking
- [ ] Permission management

### Phase 4: Advanced Features
- [ ] Persistent user memory
- [ ] Conversation search
- [ ] Advanced voice commands
- [ ] Customizable preferences

### Phase 5: Polish & Optimization
- [ ] Performance optimization
- [ ] UI/UX refinements
- [ ] Comprehensive testing
- [ ] Documentation completion

## Contributing

We welcome contributions from the community! Here's how you can help:

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Follow the existing code style and conventions
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

### Reporting Issues
- Use the GitHub issue tracker
- Include system information and steps to reproduce
- Attach relevant logs or screenshots

### Feature Requests
- Check existing issues first
- Describe the use case and expected behavior
- Consider contributing the implementation

## Privacy & Security

Nova takes privacy seriously:
- **Local Processing**: Ollama integration keeps sensitive data on-device
- **Minimal Data Collection**: Only necessary information is stored
- **User Control**: Clear options for data management and deletion
- **Secure Communication**: Encrypted API calls to external services

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- OpenAI for providing powerful AI capabilities
- Ollama team for local AI processing
- Apple for excellent development frameworks
- The open-source community for inspiration and tools

## Support

- **Documentation**: Check this README and inline code comments
- **Issues**: Report bugs via GitHub Issues
- **Discussions**: Join our community discussions
- **Email**: [Your contact email]

---

**Built with ❤️ using SwiftUI and powered by AI**
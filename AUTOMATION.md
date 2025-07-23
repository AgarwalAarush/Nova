# macOS-use Repository Analysis & Swift Backend Conversion Guide

## Overview

The **macOS-use** repository is an AI agent framework that enables natural language control of macOS applications through accessibility APIs. Built in Python, it provides both programmatic and web-based interfaces for automating complex multi-app workflows on macOS.

## Repository Structure

```
macOS-use/
├── mlx_use/                    # Core library package
│   ├── agent/                  # AI agent orchestration
│   ├── controller/             # Action execution and registry
│   ├── mac/                    # macOS accessibility integration
│   ├── telemetry/              # Usage tracking
│   └── utils.py                # Common utilities
├── examples/                   # Usage demonstrations
├── gradio_app/                 # Web interface
│   ├── app.py                  # Main Gradio application
│   ├── src/                    # Application modules
│   └── requirements.txt        # Web app dependencies
├── static/                     # Demo assets
└── pyproject.toml              # Package configuration
```

## Core Components Analysis

### 1. Agent System (`mlx_use/agent/`)

**Purpose**: Central AI orchestrator that converts natural language tasks into macOS UI interactions.

#### Key Files:
- **`service.py`** (`Agent` class):
  - Orchestrates entire agent workflow
  - Manages LLM conversation history and state
  - Integrates with LangChain for structured output
  - Handles error recovery and retry logic
  - Implements async execution with callbacks

- **`views.py`** (Data Models):
  - `AgentBrain`: Current cognitive state (evaluation, memory, next goal)
  - `AgentOutput`: Structured LLM responses with actions
  - `AgentHistory`: Complete execution tracking
  - `ActionResult`: Results of executed actions

#### Key Functions:
- `Agent.run(max_steps)`: Main execution loop
- `Agent.step()`: Single reasoning and action cycle
- Message management through `MessageManager`
- Telemetry tracking and UI callbacks

#### Dependencies:
- **LangChain** (MAJOR): LLM abstractions and structured output
- **OpenAI/Anthropic SDKs**: LLM provider integrations
- **Pydantic**: Data validation and serialization

### 2. Controller System (`mlx_use/controller/`)

**Purpose**: Action execution engine and registry management.

#### Key Files:
- **`service.py`** (`Controller` class):
  - Executes actions on macOS through accessibility APIs
  - Manages registry of available actions
  - Provides core automation primitives

#### Core Actions:
- `done`: Task completion signal
- `input_text`: Text input with submission
- `click_element`: UI element clicking
- `right_click_element`: Context menu triggering
- `scroll_element`: Directional scrolling
- `open_app`: Application launching
- `run_apple_script`: AppleScript execution

#### Key Functions:
- `multi_act()`: Execute action sequences
- `act()`: Single action execution
- Dynamic action registration system

### 3. macOS Integration Layer (`mlx_use/mac/`)

**Purpose**: Low-level macOS accessibility API integration.

#### Key Files:

- **`tree.py`** (`MacUITreeBuilder`):
  - Builds hierarchical UI representations
  - Discovers interactive elements
  - Manages element caching and indexing
  - **Key Methods**: `build_tree()`, element processing

- **`actions.py`**:
  - Direct Accessibility API operations
  - **Core Functions**: `perform_action()`, `click()`, `type_into()`, `right_click()`, `scroll()`
  - Element validation and safety checks

- **`element.py`** (`MacElementNode`):
  - UI element representation with rich metadata
  - **Key Methods**: `accessibility_path`, `find_element_by_path()`, `get_clickable_elements_string()`
  - LLM-optimized string representations

- **`context.py`** (`MacAppContext`):
  - Application lifecycle management
  - Session state handling
  - UI change notifications

#### Dependencies:
- **ApplicationServices**: Core accessibility framework
- **CoreFoundation**: Low-level system APIs
- **Cocoa**: App launching and control

### 4. Web Interface (`gradio_app/`)

**Purpose**: User-friendly web interface for task execution and configuration.

#### Key Files:

- **`app.py`**:
  - Multi-tab Gradio interface
  - Real-time terminal output streaming
  - LLM provider/model selection
  - **Tabs**: Agent execution, Automations, Configuration

- **`src/models/llm_models.py`**:
  - LLM provider integrations
  - **Supported**: OpenAI (GPT-4o, o3-mini), Anthropic (Claude 3.5/3.7 Sonnet), Google (Gemini), Alibaba (Qwen)

- **`src/config/example_prompts.py`**:
  - Categorized task examples
  - **Categories**: Quick tasks, Multi-step workflows, Expert automation, Advanced scenarios

#### Features:
- Interactive task execution
- Multi-agent workflow automation
- Configuration management
- Anonymous usage data sharing
- Real-time execution monitoring

### 5. Examples (`examples/`)

**Purpose**: Demonstrate library capabilities and usage patterns.

#### Example Categories:

**Simple Tasks**:
- `calculate.py`: Basic calculator automation
- `try.py`: Interactive agent with dynamic tasks

**Multi-Step Workflows**:
- `check_time_online.py`: Web browsing and information retrieval
- `lunch_notes.py`: Notes app interaction

**Advanced Automation**:
- `login_to_auth0.py`: Complex authentication workflow
- `excel.py`: Spreadsheet operations with conditional logic

**Utilities**:
- `print_app_tree.py`: UI tree debugging tool
- `basic_agent.py`: Low-level accessibility API usage

## Swift Backend Conversion Analysis

### ✅ DIRECT CONVERSION POSSIBLE (40% of codebase)

#### macOS Integration Layer (`mlx_use/mac/*`)
**Conversion Feasibility**: **EXCELLENT** - Would actually be better in Swift

- **Swift Advantages**:
  - Native access to ApplicationServices, CoreFoundation, Cocoa
  - No Python bridge overhead
  - Better performance for UI tree building
  - Direct Objective-C interop

- **Conversion Mapping**:
  ```swift
  // tree.py → Swift
  class MacUITreeBuilder {
      func buildTree() async -> MacElementNode
      // Direct AXUIElement API calls
  }

  // actions.py → Swift
  func performAction(element: AXUIElement, action: AXAction) throws
  func click(element: AXUIElement, actionType: ClickType) throws

  // element.py → Swift
  struct MacElementNode: Codable {
      let accessibilityPath: String
      let actions: [AXAction]
      // Native Swift structs
  }
  ```

#### Core Automation Logic
- Action execution patterns
- State management with Swift actors
- Async/await (Swift 5.5+ has excellent support)
- Element validation and safety checks

### ⚠️ MODERATE EFFORT CONVERSION (30% of codebase)

#### HTTP Clients and LLM Provider Integration
**Conversion Feasibility**: **MODERATE** - Requires custom Swift SDKs

- **Current Dependencies**: httpx, requests, provider-specific Python SDKs
- **Swift Solutions**:
  ```swift
  // Custom LLM provider protocols
  protocol LLMProvider {
      func generateStructuredResponse<T: Codable>(
          prompt: String,
          responseType: T.Type
      ) async throws -> T
  }

  class OpenAIProvider: LLMProvider { /* Custom implementation */ }
  class AnthropicProvider: LLMProvider { /* Custom implementation */ }
  ```

#### Data Models and Serialization
**Conversion Feasibility**: **GOOD** - Swift Codable vs Python Pydantic

- **Current**: Pydantic models with dynamic validation
- **Swift Alternative**: Codable protocol with type safety
  ```swift
  struct AgentBrain: Codable {
      let evaluation: String
      let memory: [String]
      let nextGoal: String
  }

  struct ActionResult: Codable {
      let success: Bool
      let error: String?
      let extractedContent: String?
  }
  ```

#### Configuration and Utilities
- Environment variable management
- Logging systems (swift-log)
- Performance monitoring decorators → Swift property wrappers

### ❌ CANNOT BE DIRECTLY CONVERTED - REQUIRES COMPLETE REIMPLEMENTATION (30% of codebase)

#### 🚨 LangChain Integration (MAJOR BLOCKER)
**Why This Is Critical**: LangChain provides the entire LLM abstraction layer

- **Current Functionality**:
  - Multi-provider LLM abstractions
  - Conversation memory management
  - Structured output parsing
  - Prompt template management
  - Retry and error handling

- **Swift Reimplementation Required**:
  ```swift
  // Would need to build from scratch
  protocol StructuredOutputParser {
      func parse<T: Codable>(_ response: String, as type: T.Type) throws -> T
  }

  class ConversationManager {
      private var history: [ChatMessage]
      func addMessage(_ message: ChatMessage)
      func getContext() -> String
  }

  class LLMOrchestrator {
      func executeWithRetry<T: Codable>(
          prompt: String,
          responseType: T.Type,
          maxRetries: Int = 3
      ) async throws -> T
  }
  ```

- **Development Effort**: 2-3 months of dedicated development
- **Complexity**: High - needs to replicate years of LangChain development

#### Gradio Web Interface
**Why This Cannot Be Converted**: No Swift equivalent to Gradio's auto-generated UIs

- **Current**: Python Gradio with automatic web UI generation
- **Swift Alternatives**:
  1. **SwiftUI Native App**: Complete paradigm shift
     ```swift
     struct AgentView: View {
         @StateObject private var agent = AgentController()
         var body: some View {
             VStack {
                 TaskInputView()
                 ExecutionView()
                 ConfigurationView()
             }
         }
     }
     ```

  2. **Swift Web Backend**: Vapor/Perfect + JavaScript frontend
     ```swift
     app.post("execute-task") { req -> EventLoopFuture<TaskResult> in
         let task = try req.content.decode(TaskRequest.self)
         return agentService.execute(task: task.description)
     }
     ```

#### Python-Specific Dependencies
**Libraries with no Swift equivalent**:
- **posthog**: Telemetry (would need Swift SDK)
- **lmnr**: Monitoring and observability
- **beautifulsoup4**: HTML parsing (not needed for macOS automation)
- **gradio**: Web UI framework

## Swift Backend Architecture Recommendations

### Proposed Swift Architecture

```swift
// Core Agent System
actor AgentOrchestrator {
    private let llmProvider: LLMProvider
    private let controller: ActionController
    private let conversationManager: ConversationManager

    func execute(task: String, maxSteps: Int = 25) async throws -> TaskResult
    func step() async throws -> StepResult
}

// LLM Abstraction Layer (Custom Implementation Required)
protocol LLMProvider {
    func generateStructuredResponse<T: Codable>(
        prompt: String,
        systemPrompt: String,
        responseType: T.Type
    ) async throws -> T
}

// macOS Integration (Direct Conversion)
class MacAccessibilityController {
    private let treeBuilder: MacUITreeBuilder
    private let actionExecutor: MacActionExecutor

    func buildUITree() async throws -> MacElementNode
    func executeAction(_ action: MacAction) async throws -> ActionResult
}

// Action System
enum MacAction: Codable {
    case click(elementPath: String)
    case type(text: String, elementPath: String)
    case scroll(direction: ScrollDirection, elementPath: String)
    case openApp(name: String)
    case done
}

protocol ActionController {
    func execute(_ action: MacAction) async throws -> ActionResult
    func getAvailableActions() -> [ActionDefinition]
}
```

### Implementation Phases

#### Phase 1: Core macOS Integration (2-3 weeks)
- Convert `mlx_use/mac/*` to native Swift
- Implement accessibility API wrappers
- Build UI tree construction system
- Create action execution primitives

#### Phase 2: LLM Provider Integration (4-6 weeks)
- Build custom LLM provider abstractions
- Implement OpenAI, Anthropic, Google Swift SDKs
- Create structured output parsing system
- Add conversation management

#### Phase 3: Agent Orchestration (2-3 weeks)
- Convert agent logic to Swift
- Implement retry and error handling
- Add state management with actors
- Create task execution framework

#### Phase 4: User Interface (3-4 weeks)
- **Option A**: SwiftUI native app
- **Option B**: Swift web backend + modern frontend
- Configuration management
- Real-time execution monitoring

### Performance Benefits of Swift Backend

1. **Native macOS Integration**: No Python bridge overhead
2. **Memory Safety**: Automatic memory management with performance
3. **Concurrency**: Modern async/await with actors
4. **Type Safety**: Compile-time error catching
5. **Performance**: 2-10x faster execution for UI operations

### Development Effort Estimation

- **Total Conversion Time**: 3-4 months full-time development
- **Team Size**: 2-3 Swift developers
- **Biggest Challenge**: LangChain reimplementation (40% of effort)
- **Easiest Parts**: macOS integration (would be significantly better)

## Key Dependencies Analysis

### Python Dependencies That Must Be Replaced

```toml
# CRITICAL - No Direct Swift Equivalent
langchain = "0.3.14"           # 🚨 MAJOR BLOCKER - Custom implementation required
langchain-openai = "0.3.1"     # 🚨 Custom Swift SDK needed
langchain-anthropic = "0.3.3"  # 🚨 Custom Swift SDK needed
gradio = "5.16.1"              # 🚨 Complete UI rewrite required

# MODERATE - Swift Alternatives Available
httpx = "0.27.2"               # ✅ URLSession or Alamofire
requests = "2.32.3"            # ✅ URLSession
pydantic = "2.10.4"            # ✅ Swift Codable
python-dotenv = "1.0.1"        # ✅ Swift environment handling

# EASY - Direct Swift Equivalent
pyobjc = "11.0.0"              # ✅ Native Swift Cocoa access
pycocoa = "25.1.18"            # ✅ Native Swift Cocoa access
```

### Swift Package Dependencies

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"), // If web backend
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"), // HTTP client
    // Custom LLM provider packages (to be developed)
]
```

## Conclusion

### Conversion Summary

- **40% Direct Conversion**: macOS integration layer (actually improved in Swift)
- **30% Moderate Effort**: HTTP clients, data models, configuration
- **30% Complete Reimplementation**: LangChain integration, web interface

### Critical Decision Point

The **LangChain dependency is the single biggest blocker** for Swift conversion. This Python library handles:
- Multi-provider LLM abstractions
- Structured output parsing
- Conversation management
- Prompt engineering
- Error handling and retries

**Recommendation**: If proceeding with Swift backend, budget 2-3 months of dedicated development for LangChain equivalent functionality. The macOS integration improvements and performance gains would be significant, but the LLM abstraction layer represents substantial custom development work.

### Alternative Approach

Consider a **hybrid architecture**:
1. Keep Python/LangChain for LLM orchestration
2. Build Swift companion library for macOS accessibility
3. Use IPC/RPC between Python brain and Swift automation engine
4. Gradual migration over time

This would leverage the strengths of both ecosystems while minimizing development risk and timeline.

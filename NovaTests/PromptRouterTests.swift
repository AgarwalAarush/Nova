//
//  PromptRouterTests.swift
//  NovaTests
//
//  Created by Aarush Agarwal on 7/17/25.
//

import XCTest
@testable import Nova

final class PromptRouterTests: XCTestCase {
    
    var promptRouter: PromptRouterService!
    var testConfig: AppConfig!
    
    override func setUpWithError() throws {
        testConfig = AppConfig.shared
        promptRouter = PromptRouterService(config: testConfig)
    }
    
    override func tearDownWithError() throws {
        promptRouter = nil
        testConfig = nil
    }
    
    func testGetSimplestModel() throws {
        // Test Claude provider
        let claudeModel = promptRouter.getSimplestModel(for: .claude)
        XCTAssertNotNil(claudeModel, "Should find a Claude model")
        
        if let model = claudeModel {
            // Should be Claude 3 Haiku (highest powerRank)
            XCTAssertEqual(model.id, "claude-3-haiku-20240307")
            XCTAssertEqual(model.powerRank, 17)
        }
        
        // Test OpenAI provider
        let openaiModel = promptRouter.getSimplestModel(for: .openai)
        XCTAssertNotNil(openaiModel, "Should find an OpenAI model")
        
        if let model = openaiModel {
            // Should be O4 Mini (highest powerRank)
            XCTAssertEqual(model.id, "o4-mini")
            XCTAssertEqual(model.powerRank, 16)
        }
    }
    
    func testFormatToolsSchema() throws {
        let testSchema = """
        {
            "tools": [
                {"name": "test_tool", "description": "Test tool"}
            ]
        }
        """
        
        let formatted = promptRouter.formatToolsSchema(testSchema)
        
        XCTAssertTrue(formatted.contains("Here are the available automation tools"))
        XCTAssertTrue(formatted.contains(testSchema))
        XCTAssertTrue(formatted.contains("Important guidelines"))
    }
    
    func testToolCallStructure() throws {
        let toolCall = ToolCall(name: "testTool", parameters: ["key": "value"])
        
        XCTAssertEqual(toolCall.name, "testTool")
        XCTAssertEqual(toolCall.parameters["key"] as? String, "value")
    }
    
    func testPromptRouterResponse() throws {
        let toolCalls = [
            ToolCall(name: "updateUserPreferences", parameters: ["preferences": ["test preference"]]),
            ToolCall(name: "captureScreen", parameters: [:])
        ]
        
        let response = PromptRouterResponse(
            toolCalls: toolCalls,
            reasoning: "Test reasoning",
            requiresUserInput: false,
            estimatedExecutionTime: 5.0
        )
        
        XCTAssertEqual(response.toolCalls.count, 2)
        XCTAssertEqual(response.reasoning, "Test reasoning")
        XCTAssertFalse(response.requiresUserInput)
        XCTAssertEqual(response.estimatedExecutionTime, 5.0)
    }
    
    @MainActor
    func testPromptRouterIntegration() async throws {
        // Test that AIServiceRouter can be initialized with promptRouter
        let aiServiceRouter = AIServiceRouter(config: testConfig)
        
        // Verify that the service router was created successfully
        XCTAssertNotNil(aiServiceRouter)
        XCTAssertEqual(aiServiceRouter.currentProvider, testConfig.aiProvider)
    }
}
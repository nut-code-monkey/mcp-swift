import MCP
import Foundation

func toolset(for server: Server) -> MCPHTTPServer.Toolset<Tool, CallTool> {
    var toolset = MCPHTTPServer.Toolset<Tool, CallTool>()
    toolset.register(tool: Tool(
        name: "test_simple_text",
        description: "Tests simple text content response",
        inputSchema: .object(["type": "object", "properties": [:]])
    )) { _ in
            .init(content: [.text(text: "This is a simple text response for testing.", annotations: nil, _meta: nil)], isError: false)
    }
    
    let testImageBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="
    toolset.register(tool: Tool(
        name: "test_image_content",
        description: "Tests image content response",
        inputSchema: .object(["type": "object", "properties": [:]])
    )) { _ in
            .init(content: [.image(data: testImageBase64, mimeType: "image/png", annotations: nil, _meta: nil)], isError: false)
    }
    
    toolset.register(tool: Tool(
        name: "test_audio_content",
        description: "Tests audio content response",
        inputSchema: .object(["type": "object", "properties": [:]])
    )) { _ in
        let testAudioBase64 = "UklGRiYAAABXQVZFZm10IBAAAAABAAEAQB8AAAB9AAACABAAZGF0YQIAAAA="
        return .init(content: [.audio(data: testAudioBase64, mimeType: "audio/wav", annotations: nil, _meta: nil)], isError: false)
    }
    
    toolset.register(tool:  Tool(
        name: "test_embedded_resource",
        description: "Tests embedded resource content response",
        inputSchema: .object(["type": "object", "properties": [:]])
    )) { _ in
            .init(content: [.resource(resource: .text("This is an embedded resource content.",
                                                      uri: "test://embedded-resource",
                                                      mimeType: "text/plain"))], isError: false)
    }
    
    toolset.register(tool: Tool(
        name: "test_multiple_content_types",
        description: "Tests response with multiple content types",
        inputSchema: .object(["type": "object", "properties": [:]])
    )) { _ in
            .init(content: [
                .text(text: "Multiple content types test:", annotations: nil, _meta: nil),
                .image(data: testImageBase64, mimeType: "image/png", annotations: nil, _meta: nil),
                .resource(resource: .text("{\"test\":\"data\",\"value\":123}",
                                          uri: "test://mixed-content-resource",
                                          mimeType: "application/json"))
            ], isError: false)
    }
    
    toolset.register(tool: Tool(
        name: "test_error_handling",
        description: "Tests error response handling",
        inputSchema: .object(["type": "object", "properties": [:]])
    )) { _ in
            .init(content: [.text(text: "An error occurred during tool execution", annotations: nil, _meta: nil)], isError: true)
    }
    
    
    toolset.register(tool: Tool(
        name: "test_logging",
        description: "Tests logging capabilities",
        inputSchema: .object(["type": "object", "properties": [:]])
    )) { _ in
            .init(content: [.text(text: "Logging test completed", annotations: nil, _meta: nil)], isError: false)
    }
    
    
    toolset.register(tool: Tool(
        name: "test_progress",
        description: "Tests progress notifications",
        inputSchema: .object([
            "type": "object",
            "properties": [
                "duration_ms": [
                    "type": "number",
                    "description": "Duration in milliseconds to report progress"
                ]
            ]
        ])
    )) { params in
        let duration = params.arguments?["duration_ms"]?.intValue ?? 1000
        try? await Task.sleep(for: .milliseconds(duration))
        return .init(content: [.text(text: "Progress test completed", annotations: nil, _meta: nil)], isError: false)
    }
    
    
    toolset.register(tool: Tool(
        name: "add_numbers",
        description: "Adds two numbers together",
        inputSchema: .object([
            "type": "object",
            "properties": [
                "a": [
                    "type": "number",
                    "description": "First number"
                ],
                "b": [
                    "type": "number",
                    "description": "Second number"
                ]
            ]
        ])
    )) { params in
        guard let a = params.arguments?["a"]?.intValue, let b = params.arguments?["b"]?.intValue else {
            return .init(content: [.text(text: "Invalid arguments: expected numbers a and b", annotations: nil, _meta: nil)], isError: true)
        }
        return .init(content: [.text(text: "\(a + b)", annotations: nil, _meta: nil)], isError: false)
    }
    
    
    toolset.register(tool: Tool(
        name: "test_tool_with_progress",
        description: "Tool reports progress notifications",
        inputSchema: .object([
            "type": "object",
            "properties": [:]])
    )) { [weak server] params in
        if let token = params._meta?.progressToken, let server {
            let notification1 = ProgressNotification.message(
                .init(progressToken: token, progress: 0, total: 100)
            )
            try await server.notify(notification1)
            try await Task.sleep(for: .microseconds(50))
            
            let notification2 = ProgressNotification.message(
                .init(progressToken: token, progress: 50, total: 100)
            )
            try await server.notify(notification2)
            try await Task.sleep(for: .microseconds(50))
            
            let notification3 = ProgressNotification.message(
                .init(progressToken: token, progress: 100, total: 100)
            )
            try await server.notify(notification3)
        }
        
        return .init(content: [.text(text: "This is a simple text response for testing.", annotations: nil, _meta: nil)], isError: false)
    }
    
    
    toolset.register(tool: Tool(
        name: "test_tool_with_logging",
        description: "Tool sends log messages during execution",
        inputSchema: .object(["type": "object", "properties": [:]])
    )) { [weak server] params in
        // Send first log message
        let log1 = LogMessageNotification.message(
            .init(level: .info, data: .string("Tool execution started"))
        )
        try await server?.notify(log1)
        
        // Wait 50ms
        try await Task.sleep(for: .milliseconds(50))
        
        // Send second log message
        let log2 = LogMessageNotification.message(
            .init(level: .info, data: .string("Tool processing data"))
        )
        try await server?.notify(log2)
        
        // Wait another 50ms
        try await Task.sleep(for: .milliseconds(50))
        
        // Send third log message
        let log3 = LogMessageNotification.message(
            .init(level: .info, data: .string("Tool execution completed"))
        )
        try await server?.notify(log3)
        
        return .init(content: [.text(text: "Logging test completed", annotations: nil, _meta: nil)], isError: false)
    }
    
    
    toolset.register(tool: Tool(
        name: "test_sampling",
        description: "Tests LLM sampling capabilities",
        inputSchema: .object([
            "type": "object",
            "properties": [
                "prompt": [
                    "type": "string",
                    "description": "Text to send to the LLM"
                ]
            ],
            "required": ["prompt"]
        ])
    )) { [weak server] params in
        // Test LLM sampling - request sampling/createMessage from client
        guard let prompt = params.arguments?["prompt"]?.stringValue else {
            return .init(content: [.text(text: "Missing required argument: prompt", annotations: nil, _meta: nil)], isError: true)
        }
        
        let samplingResult = try await server?.requestSampling(
            messages: [.user(.text(prompt))],
            maxTokens: 100
        )
        
        let responseText = samplingResult?.content.asArray
            .compactMap { block -> String? in
                if case .text(let text) = block {
                    return text
                }
                return nil
            }
            .joined(separator: "\n") ?? "No response"
        
        return .init(content: [.text(text: responseText, annotations: nil, _meta: nil)], isError: false)
    }
    
    
    toolset.register(tool: Tool(
        name: "test_elicitation",
        description: "Tests user input elicitation",
        inputSchema: .object([
            "type": "object",
            "properties": [
                "message": [
                    "type": "string",
                    "description": "Text displayed to user"
                ]
            ],
            "required": ["message"]
        ])
    )) { [weak server] params in
        // Test elicitation - request user input for username and email
        guard let message = params.arguments?["message"]?.stringValue else {
            return .init(content: [.text(text: "Missing required argument: message", annotations: nil, _meta: nil)], isError: true)
        }
        
        let elicitationResult = try await server?.requestElicitation(
            message: message,
            requestedSchema: Elicitation.RequestSchema(
                properties: [
                    "username": .object(["type": .string("string")]),
                    "email": .object(["type": .string("string")])
                ],
                required: ["username", "email"]
            )
        )
        
        return .init(
            content: [.text(text: "Elicitation completed: action=\(elicitationResult?.action.rawValue ?? "unknown"), content=\(elicitationResult?.content ?? [:])", annotations: nil, _meta: nil)],
            isError: false
        )
    }
    
    
    
    toolset.register(tool: Tool(
        name: "test_elicitation_sep1034_defaults",
        description: "Tests elicitation with default values (SEP-1034)",
        inputSchema: .object(["type": "object", "properties": [:]])
    )) { [weak server] params in
        let elicitationResult = try await server?.requestElicitation(
            message: "Please provide the following information:",
            requestedSchema: Elicitation.RequestSchema(
                properties: [
                    "name": .object([
                        "type": .string("string"),
                        "default": .string("John Doe")
                    ]),
                    "age": .object([
                        "type": .string("integer"),
                        "default": .int(30)
                    ]),
                    "score": .object([
                        "type": .string("number"),
                        "default": .double(95.5)
                    ]),
                    "status": .object([
                        "type": .string("string"),
                        "enum": .array([.string("active"), .string("inactive"), .string("pending")]),
                        "default": .string("active")
                    ]),
                    "verified": .object([
                        "type": .string("boolean"),
                        "default": .bool(true)
                    ])
                ]
            )
        )
        
        return .init(
            content: [.text(text: "Elicitation completed: action=\(elicitationResult?.action.rawValue ?? "unknown"), content=\(elicitationResult?.content ?? [:])", annotations: nil, _meta: nil)],
            isError: false
        )
    }
    
    
    toolset.register(tool: Tool(
        name: "test_elicitation_sep1330_enums",
        description: "Tests elicitation with enum variants (SEP-1330)",
        inputSchema: .object(["type": "object", "properties": [:]])
    )) { [weak server] params in
        // Test elicitation with enum variants (SEP-1330)
        let elicitationResult = try await server?.requestElicitation(
            message: "Select options for enum testing:",
            requestedSchema: Elicitation.RequestSchema(
                properties: [
                    // 1. Untitled single-select
                    "untitledSingle": .object([
                        "type": .string("string"),
                        "enum": .array([.string("option1"), .string("option2"), .string("option3")])
                    ]),
                    // 2. Titled single-select
                    "titledSingle": .object([
                        "type": .string("string"),
                        "oneOf": .array([
                            .object(["const": .string("opt1"), "title": .string("Option One")]),
                            .object(["const": .string("opt2"), "title": .string("Option Two")]),
                            .object(["const": .string("opt3"), "title": .string("Option Three")])
                        ])
                    ]),
                    // 3. Legacy titled (deprecated enumNames)
                    "legacyEnum": .object([
                        "type": .string("string"),
                        "enum": .array([.string("legacy1"), .string("legacy2"), .string("legacy3")]),
                        "enumNames": .array([.string("Legacy One"), .string("Legacy Two"), .string("Legacy Three")])
                    ]),
                    // 4. Untitled multi-select
                    "untitledMulti": .object([
                        "type": .string("array"),
                        "items": .object([
                            "type": .string("string"),
                            "enum": .array([.string("multi1"), .string("multi2"), .string("multi3")])
                        ])
                    ]),
                    // 5. Titled multi-select
                    "titledMulti": .object([
                        "type": .string("array"),
                        "items": .object([
                            "anyOf": .array([
                                .object(["const": .string("titled1"), "title": .string("Titled One")]),
                                .object(["const": .string("titled2"), "title": .string("Titled Two")]),
                                .object(["const": .string("titled3"), "title": .string("Titled Three")])
                            ])
                        ])
                    ])
                ]
            )
        )
        
        return .init(
            content: [.text(text: "Elicitation completed: action=\(elicitationResult?.action.rawValue ?? "unknown"), content=\(elicitationResult?.content ?? [:])", annotations: nil, _meta: nil)],
            isError: false
        )
    }
    
    toolset.register(tool: Tool(
        name: "test_client_elicitation_defaults",
        description: "Tests that client applies defaults for omitted elicitation fields",
        inputSchema: .object(["type": "object", "properties": [:]])
    )) { [weak server] params in
        // Tool for client-side elicitation defaults test
        let elicitationResult = try await server?.requestElicitation(
            message: "Please provide your information (defaults available):",
            requestedSchema: Elicitation.RequestSchema(
                properties: [
                    "name": .object([
                        "type": .string("string"),
                        "default": .string("John Doe")
                    ]),
                    "age": .object([
                        "type": .string("integer"),
                        "default": .int(30)
                    ]),
                    "score": .object([
                        "type": .string("number"),
                        "default": .double(95.5)
                    ]),
                    "status": .object([
                        "type": .string("string"),
                        "enum": .array([.string("active"), .string("inactive"), .string("pending")]),
                        "default": .string("active")
                    ]),
                    "verified": .object([
                        "type": .string("boolean"),
                        "default": .bool(true)
                    ])
                ]
            )
        )
        
        // Verify the client applied defaults correctly
        guard let content = elicitationResult?.content,
              let name = content["name"]?.stringValue,
              let age = content["age"]?.intValue,
              let score = content["score"]?.doubleValue,
              let status = content["status"]?.stringValue,
              let verified = content["verified"]?.boolValue else {
            return .init(content: [.text(text: "Client did not provide all required fields with defaults", annotations: nil, _meta: nil)], isError: true)
        }
        
        guard name == "John Doe", age == 30, score == 95.5, status == "active", verified == true else {
            return .init(content: [.text(text: "Client defaults do not match expected values", annotations: nil, _meta: nil)], isError: true)
        }
        
        return .init(
            content: [.text(text: "Client correctly applied all default values", annotations: nil, _meta: nil)],
            isError: false
        )
    }
    
    
    toolset.register(tool: Tool(
        name: "json_schema_2020_12_tool",
        description: "Tool with JSON Schema 2020-12 features",
        inputSchema: .object([
            "$schema": .string("https://json-schema.org/draft/2020-12/schema"),
            "type": .string("object"),
            "$defs": .object([
                "address": .object([
                    "type": .string("object"),
                    "properties": .object([
                        "street": .object(["type": .string("string")]),
                        "city": .object(["type": .string("string")])
                    ])
                ])
            ]),
            "properties": .object([
                "name": .object(["type": .string("string")]),
                "address": .object(["$ref": .string("#/$defs/address")])
            ]),
            "additionalProperties": .bool(false)
        ])
    )) { _ in
            .init(content: [.text(text: "This is a simple text response for testing.", annotations: nil, _meta: nil)], isError: false)
    }
    
    return toolset
}


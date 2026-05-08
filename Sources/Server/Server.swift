import Foundation
import MCP

// MARK: - Server Setup

extension MCPHTTPServer {
    struct Toolset<Tool, T>: Sendable where T: MCP.Method, Tool: Hashable & Sendable {
        typealias Handler = @Sendable (T.Parameters) async throws -> T.Result
        private var _tools: [Tool: Handler] = [:]
        mutating func register(tool: Tool, handler: @escaping Handler) {
            _tools[tool] = handler
        }
        var tools: [Tool] { Array(_tools.keys) }
        var handlers: [Handler] { Array(_tools.values) }
        func handler(where  condition: (Tool) -> Bool) -> Handler? {
            _tools.first(where: { condition( $0.key ) })?.value
        }
    }
}

func createServer(
    state: ServerState,
    transport: StatefulHTTPServerTransport,
    sessionID: String
) async -> Server {
    let server = Server(
        name: "mcp-conformance-test-server",
        version: "1.0.0",
        capabilities: Server.Capabilities(
            completions: .init(),
            logging: .init(),
            prompts: .init(listChanged: true),
            resources: .init(subscribe: true, listChanged: true),
            tools: .init(listChanged: true)
        )
    )
    
    // Tools
    let toolset = toolset(for: server)
    await server.withMethodHandler(ListTools.self) { _ in
        .init(tools: toolset.tools)
    }
    
    await server.withMethodHandler(CallTool.self) { params in
        if let handler = toolset.handler(where: { $0.name == params.name }) {
            return try await handler(params)
        }
        return .init(content: [.text(text: "Unknown tool: \(params.name)", annotations: nil, _meta: nil)], isError: true)
    }
    

    // Resources
    let resources = resourcesStatic(state)
    let template = resourcesTemplate()
    await server.withMethodHandler(ListResources.self) { _ in
        return .init(resources: resources.tools + template.tools)
    }
    
    await server.withMethodHandler(ReadResource.self) { params in
        if let handler = resources.handler(where: { $0.uri == params.uri }) {
            return try await handler(params)
        }
        
        for handler in template.handlers {
            do {
                return try await handler(params)
            } catch { continue }
        }
        
        return .init(contents: [.text("Resource not found: \(params.uri)", uri: params.uri)])
    }
    
    await server.withMethodHandler(ResourceSubscribe.self) { params in
        await state.subscribe(to: params.uri)
        return Empty()
    }
    
    await server.withMethodHandler(ResourceUnsubscribe.self) { params in
        await state.unsubscribe(from: params.uri)
        return Empty()
    }
    
    // Prompts
    let prompts = prompts()
    await server.withMethodHandler(ListPrompts.self) { _ in
        .init(prompts: prompts.tools)
    }
    
    await server.withMethodHandler(GetPrompt.self) { params in
        guard let handler = prompts.handler(where: { $0.name == params.name }) else {
            throw MCPError.invalidRequest("Unknown prompt: \(params.name)")
        }
        return try await handler(params)
    }
    
    await server.withMethodHandler(SetLoggingLevel.self) { _ in
        // Accept any logging level (debug, info, notice, warning, error, critical, alert, emergency)
        // For conformance testing, we just accept it without doing anything
        return Empty()
    }
    
    await server.withMethodHandler(Complete.self) { _ in
        return .init(completion: .init(values: []))
    }
    
    return server
}


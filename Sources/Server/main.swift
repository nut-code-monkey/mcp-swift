/**
 * MCP HTTP Server Wrapper
 *
 * HTTP server that wraps the MCP conformance server for testing with the
 * official conformance framework.
 *
 * Usage: mcp-http-server [--port PORT]
 */

import Foundation
import Logging
import MCP
import MCPServer

#if canImport(FoundationNetworking)
    import FoundationNetworking

#endif

// MARK: - Server State

actor ServerState {
    var resourceSubscriptions: Set<String> = []
    var watchedResourceContent = "Watched resource content"

    func subscribe(to uri: String) {
        resourceSubscriptions.insert(uri)
    }

    func unsubscribe(from uri: String) {
        resourceSubscriptions.remove(uri)
    }

    func isSubscribed(to uri: String) -> Bool {
        resourceSubscriptions.contains(uri)
    }

    func updateWatchedResource(_ newContent: String) {
        watchedResourceContent = newContent
    }
}


// MARK: - HTTP Server

// MCPHTTPServer handles all HTTP server functionality

// MARK: - Main
struct MCPHTTPServer {
    static func run() async throws {
        let args = CommandLine.arguments
        var port = 3001

        for (index, arg) in args.enumerated() {
            if arg == "--port" && index + 1 < args.count {
                if let p = Int(args[index + 1]) {
                    port = p
                }
            }
        }

        var loggerConfig = Logger(label: "mcp.http.server", factory: { StreamLogHandler.standardError(label: $0) })
        loggerConfig.logLevel = .trace
        let logger = loggerConfig

        let state = ServerState()

        logger.info("Starting MCP HTTP Server...", metadata: ["port": "\(port)"])

        let app = HTTPApp(
            configuration: .init(
                host: "localhost",
                port: port,
                endpoint: "/mcp",
                retryInterval: 1000
            ),
            validationPipeline: StandardValidationPipeline(validators: [
                OriginValidator.localhost(port: port),
                AcceptHeaderValidator(mode: .sseRequired),
                ContentTypeValidator(),
                ProtocolVersionValidator(),
                SessionValidator(),
            ]),
            serverFactory: { sessionID, transport in
                logger.debug("Creating server for session", metadata: ["sessionID": "\(sessionID)"])
                return await createServer(state: state, transport: transport, sessionID: sessionID)
            },
            logger: logger
        )

        try await app.start()
    }
}

do {
    try await MCPHTTPServer.run()
} catch {
    print(error)
    exit(1)
}

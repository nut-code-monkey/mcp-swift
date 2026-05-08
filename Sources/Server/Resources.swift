import Foundation
import MCP

func resourcesStatic(_ state: ServerState) -> MCPHTTPServer.Toolset<Resource, ReadResource> {
    var toolset = MCPHTTPServer.Toolset<Resource, ReadResource>()
    
    toolset.register(tool: Resource(
        name: "Static Text Resource",
        uri: "test://static-text",
        description: "A simple static text resource",
        mimeType: "text/plain"
    )) { params in
            .init(contents: [.text("This is static text content for testing.", uri: params.uri, mimeType: "text/plain")])
    }
    
    
    toolset.register(tool: Resource(
        name: "Static Binary Resource",
        uri: "test://static-binary",
        description: "A simple static binary resource",
        mimeType: "application/octet-stream"
    )) { params in
        let testImageBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="
        guard let imageData = Data(base64Encoded: testImageBase64) else {
            return .init(contents: [.text("Failed to decode binary data", uri: params.uri)])
        }
        return .init(contents: [.binary(imageData, uri: params.uri, mimeType: "application/octet-stream")])
    }
    
    
    toolset.register(tool: Resource(
        name: "Watched Resource",
        uri: "test://watched",
        description: "A resource that can be subscribed to for updates",
        mimeType: "text/plain"
    )) { params in
        let content = await state.watchedResourceContent
        return .init(contents: [.text(content, uri: params.uri)])
    }
    
    return toolset
}

func resourcesTemplate() -> MCPHTTPServer.Toolset<Resource, ReadResource> {
    enum TemplateError: Error {
        case notMatch
    }
    
    var toolset = MCPHTTPServer.Toolset<Resource, ReadResource>()
    
    toolset.register(tool: Resource(
        name: "Template Resource",
        uri: "test://template/{id}",
        description: "A resource template with URI parameters",
        mimeType: "text/plain"
    )) { params in
        guard params.uri.hasPrefix("test://template/") else {
            throw TemplateError.notMatch
        }
        
        let id = String(params.uri.dropFirst("test://template/".count))
        return .init(contents: [.text("Template resource with id: \(id)", uri: params.uri)])
    }
    
    return toolset
}

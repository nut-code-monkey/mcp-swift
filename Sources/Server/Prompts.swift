import Foundation
import MCP

func prompts() -> MCPHTTPServer.Toolset<Prompt, GetPrompt> {
    var toolset = MCPHTTPServer.Toolset<Prompt, GetPrompt>()
    
    toolset.register(tool: Prompt(
        name: "test_simple_prompt",
        description: "A simple prompt without arguments"
    )) { params in
        .init(description: "Simple prompt response", messages: [.user(.text(text: "This is a simple prompt for testing."))])
    }
    
    
    toolset.register(tool: Prompt(
        name: "test_prompt_with_arguments",
        description: "A prompt that accepts arguments",
        arguments: [
            Prompt.Argument(
                name: "arg1",
                description: "First test argument",
                required: true),
            Prompt.Argument(
                name: "arg2",
                description: "Second test argument",
                required: true)
        ]
    )) { params in
        let arg1 = params.arguments?["arg1"] ?? "default1"
        let arg2 = params.arguments?["arg2"] ?? "default2"
        return .init(description: "Prompt with arguments", messages: [.user(.text(text: "Prompt with arguments: arg1='\(arg1)', arg2='\(arg2)'"))])
    }

    
    toolset.register(tool: Prompt(
        name: "test_prompt_with_embedded_resource",
        description: "A prompt that includes embedded resources",
        arguments: [
            Prompt.Argument(
                name: "resourceUri",
                description: "URI of the resource to embed",
                required: true
            )
        ])
    ) { params in
        let resourceUri = params.arguments?["resourceUri"] ?? "test://default"
        return .init(description: "Prompt with embedded resource", messages: [
            .user(.resource(resource: .text("Embedded resource content for testing.", uri: resourceUri, mimeType: "text/plain"))),
            .user(.text(text: "Please process the embedded resource above."))
        ])
    }
    
    
    toolset.register(tool: Prompt(
        name: "test_prompt_with_image",
        description: "A prompt with image content"
    )) { params in
        let testImageBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="
        return .init(description: "Prompt with image", messages: [
            .user(.image(data: testImageBase64, mimeType: "image/png")),
            .user(.text(text: "Please analyze the image above."))
        ])
    }
    
    return toolset
}

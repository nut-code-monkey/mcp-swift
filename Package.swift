// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mcp-swift",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "MCPServer", targets: ["MCPServer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.12.1"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.99.0"),
    ],
    targets: [
        .target(
            name: "MCPServer",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ]
        ),
        
        .executableTarget(
            name: "Server",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .target(name: "MCPServer"),
//                .product(name: "NIOCore", package: "swift-nio"),
//                .product(name: "NIOPosix", package: "swift-nio"),
//                .product(name: "NIOHTTP1", package: "swift-nio"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

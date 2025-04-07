// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "swift-package-registry-service",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.113.2"),
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.7.1"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.1"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.2"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.8.1"),
        .package(url: "https://github.com/apple/swift-http-types", from: "1.3.1"),
        .package(url: "https://github.com/swift-server/async-http-client", from: "1.25.2"),
        .package(url: "https://github.com/pointfreeco/swift-overture.git", from: "0.5.0"),
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras.git", from: "1.3.1"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.81.0"),
        .package(url: "https://github.com/groue/Semaphore.git", from: "0.1.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.12.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.8.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "Semaphore", package: "Semaphore"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .target(name: "ChecksumClientImpl"),
                .target(name: "GithubAPIClientImpl"),
                .target(name: "APIUtilities"),
                .target(name: "HTTPStreamClient"),
                .target(name: "PersistenceClient"),
            ]
        ),
        .target(
            name: "GithubOpenAPI",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
            ]
        ),
        .target(
            name: "GithubAPIClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "Overture", package: "swift-overture"),
            ]
        ),
        .target(
            name: "GithubAPIClientImpl",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
                .target(name: "GithubAPIClient"),
                .target(name: "GithubOpenAPI"),
                .target(name: "ClientAuthMiddleware"),
                .target(name: "ClientLoggingMiddleware"),
                .target(name: "ClientStaticHeadersMiddleware"),
            ]
        ),
        .target(
            name: "APIUtilities",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .target(
            name: "ClientAuthMiddleware",
            dependencies: [
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
            ]
        ),
        .target(
            name: "ClientLoggingMiddleware",
            dependencies: [
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .target(
            name: "ClientStaticHeadersMiddleware",
            dependencies: [
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
            ]
        ),
        .target(
            name: "ChecksumClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "ChecksumClientImpl",
            dependencies: [
                .target(name: "ChecksumClient"),
                .target(name: "FileClient"),
                .target(name: "HTTPStreamClient"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .target(
            name: "HTTPStreamClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]
        ),
        .target(
            name: "PersistenceClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "Overture", package: "swift-overture"),
                .target(name: "FileClient"),
                .target(name: "APIUtilities"),
                .target(name: "HTTPStreamClient"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "NIOCore", package: "swift-nio"),
            ]
        ),
        .target(
            name: "FileClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "Semaphore", package: "Semaphore"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "_NIOFileSystem", package: "swift-nio"),
                .product(name: "Overture", package: "swift-overture"),
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .product(name: "VaporTesting", package: "vapor"),
                .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
                .product(name: "Overture", package: "swift-overture"),
                .target(name: "App"),
            ],
            resources: [
                .process("Resources/swift-overture-0.5.0.zip"),
            ]
        ),
        .testTarget(
            name: "APIUtilitiesTests",
            dependencies: [
                .target(name: "APIUtilities"),
            ]
        ),
        .testTarget(
            name: "ChecksumClientImplTests",
            dependencies: [
                .target(name: "ChecksumClientImpl"),
            ],
            resources: [
                .process("Resources/swift-overture-0.5.0.zip"),
            ]
        ),
        .testTarget(
            name: "FileClientTests",
            dependencies: [
                .target(name: "FileClient"),
            ]
        )
    ]
)

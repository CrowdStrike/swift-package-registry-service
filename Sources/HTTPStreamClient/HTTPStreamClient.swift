import AsyncHTTPClient
import DependenciesMacros

@DependencyClient
public struct HTTPStreamClient: Sendable {
    public var execute: @Sendable (HTTPClientRequest) async throws -> HTTPClientResponse = { _ in
        reportIssue("\(Self.self).execute not implemented")
        return .mock
    }
}

extension HTTPStreamClient {
    public static let mock = Self()
}

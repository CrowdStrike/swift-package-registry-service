import DependenciesMacros
import NIOCore

@DependencyClient
public struct FileClient: Sendable {
    /// Reads an entire file at the specified path
    public var readFile: @Sendable (_ path: String) async throws -> ByteBuffer = { _ in
        reportIssue("\(Self.self).readFile not implemented")
        return .init()
    }

    /// Writes an entire file to the specified path
    public var writeFile: @Sendable (_ buffer: ByteBuffer, _ path: String) async throws -> Void = { _, _ in
        reportIssue("\(Self.self).writeFile not implemented")
    }
}

public enum FileClientError: Error, Sendable {
    case fileNotFound(String)
}

extension FileClient {
    public static let mock = Self()
}

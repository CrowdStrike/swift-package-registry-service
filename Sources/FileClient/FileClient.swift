import DependenciesMacros
import NIOCore

/// An abstraction for a local filesystem
///
/// This provides simple APIs for reading and writing to the local filesystem.
/// For now, you can only read an entire into a `ByteBuffer` as well as write
/// an entire `ByteBuffer` out to a file.
///
/// To create a live version, use `FileClient.live()`.
/// To use `FileClient` in a unit test, create a `FileClient` using `FileClient.test()`.
@DependencyClient
public struct FileClient: Sendable {
    /// Reads an entire file at the specified path into a `ByteBuffer`
    ///
    /// - Parameters:
    ///   - path: The absolute path to the file to be read.
    /// - Returns: A `ByteBuffer` containing the entire file.
    /// - Throws: If the file does not exist, then this method throws `FileClientError.fileNotFound`.
    ///   If the read fails for some other reason, it will be a `FileSystemError`.
    public var readFile: @Sendable (_ path: String) async throws -> ByteBuffer = { _ in
        reportIssue("\(Self.self).readFile not implemented")
        return .init()
    }

    /// Writes an entire file to the specified path
    ///
    /// If the file already exists, it will be overwritten.
    ///
    /// - Parameters:
    ///   - buffer: a `ByteBuffer` to be written to disk.
    ///   - path: The absolute path to the file to be written.
    public var writeFile: @Sendable (_ buffer: ByteBuffer, _ path: String) async throws -> Void = { _, _ in
        reportIssue("\(Self.self).writeFile not implemented")
    }
}

/// These are errors thrown by `FileClient`.
public enum FileClientError: Error, Sendable {
    /// The file to be read was not found.
    case fileNotFound(String)
}

extension FileClient {
    public static let mock = Self()
}

import Foundation
import DependenciesMacros

@DependencyClient
public struct ChecksumClient: Sendable {
    public var computeFileChecksum: @Sendable (_ path: String) async throws -> String = { _ in
        reportIssue("\(Self.self).computeFileChecksum not implemented")
        return ""
    }
}

extension ChecksumClient {
    public static let mock = Self()
}

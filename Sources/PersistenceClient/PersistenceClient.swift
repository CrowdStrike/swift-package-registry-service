import APIUtilities
import Foundation
import DependenciesMacros
import FileClient

@DependencyClient
public struct PersistenceClient: Sendable {
    /// Reads all tags for the specified owner and repo
    public var readTags: @Sendable (_ owner: String, _ repo: String) async throws -> TagFile = { _, _ in
        reportIssue("\(Self.self).readTags not implemented")
        return .mock
    }
    /// Save the specified tags
    public var saveTags: @Sendable (_ owner: String, _ repo: String, _ tagFile: TagFile) async throws -> Void = { _, _, _ in
        reportIssue("\(Self.self).saveTags not implemented")
    }
}

public enum PersistenceClientError: Swift.Error {
    case releasesHaveMixedOwnerRepo
    case couldNotDownloadZipBall(Int)
    case noSemanticVersion(String)
    case manifestHasNoContents
}

extension PersistenceClient {
    public static let mock = Self()
}

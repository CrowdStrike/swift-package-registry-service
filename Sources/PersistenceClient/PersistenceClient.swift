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
    /// Read the source archive for a single release for the specified owner, repo, and version
    public var readSourceArchive: @Sendable (_ owner: String, _ repo: String, _ version: Version) async throws -> SourceArchive? = { _, _, _ in
        reportIssue("\(Self.self).readSourceArchive not implemented")
        return nil
    }
    /// Download the zipBallURL to cache and return the path to the cached zip file in the filesystem
    public var saveSourceArchive: @Sendable(_ owner: String, _ repo: String, _ version: Version, _ zipBallURL: String) async throws -> String = { _, _, _, _ in
        reportIssue("\(Self.self).saveSourceArchive not implemented")
        return ""
    }
    /// Read the metadata (including zipBall checksum) for a single release for the specified owner, repo, and version
    public var readReleaseMetadata: @Sendable (_ owner: String, _ repo: String, _ version: Version) async throws -> ReleaseMetadata? = { _, _, _ in
        reportIssue("\(Self.self).readReleaseMetadata not implemented")
        return nil
    }
    /// Save the metadata (including zipBall checksum) for a single release for the specified owner, repo, and version (version is inside `ReleaseMetadata`)
    public var saveReleaseMetadata: @Sendable (_ owner: String, _ repo: String, _ metadata: ReleaseMetadata) async throws -> Void = { _, _, _ in
        reportIssue("\(Self.self).saveReleaseMetadata not implemented")
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

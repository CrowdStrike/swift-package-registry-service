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
    /// Reads all releases for the specified owner and repo
    public var readReleases: @Sendable (_ owner: String, _ repo: String) async throws -> [Release] = { _, _ in
        reportIssue("\(Self.self).readReleases not implemented")
        return []
    }
    /// Save the specified releases
    public var saveReleases: @Sendable (_ releases: [Release]) async throws -> Void = { _ in
        reportIssue("\(Self.self).saveReleases not implemented")
    }
    /// Download the zipBallURL to cache and return the path to the cached zip file in the filesystem
    public var saveZipBall: @Sendable(_ owner: String, _ repo: String, _ version: Version, _ zipBallURL: String) async throws -> String = { _, _, _, _ in
        reportIssue("\(Self.self).saveZipBall not implemented")
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
    /// Read the source archive for a single release for the specified owner, repo, and version
    public var readSourceArchive: @Sendable (_ owner: String, _ repo: String, _ version: Version) async throws -> SourceArchive? = { _, _, _ in
        reportIssue("\(Self.self).readSourceArchive not implemented")
        return nil
    }
    /// Read the manifests for a single release for the specified owner, repo, and version
    public var readManifests: @Sendable (_ owner: String, _ repo: String, _ version: Version) async throws -> [Manifest] = { _, _, _ in
        reportIssue("\(Self.self).readManifests not implemented")
        return []
    }
    /// Save the manfests for a single release for the specified owner, repo, and version
    public var saveManifests: @Sendable (_ owner: String, _ repo: String, _ version: Version, _ manifests: [Manifest]) async throws -> Void = { _, _, _, _ in
        reportIssue("\(Self.self).saveManifests not implemented")
    }
    /// Read the repositories information
    public var readRepositories: @Sendable () async throws -> RepositoriesFile = {
        reportIssue("\(Self.self).readRepositories not implemented")
        return .mock
    }
    /// Save the repositories information
    public var saveRepositories: @Sendable (_ repositoriesFile: RepositoriesFile) async throws -> Void = { _ in
        reportIssue("\(Self.self).saveRepositories not implemented")
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

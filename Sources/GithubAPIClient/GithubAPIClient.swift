import Foundation
import DependenciesMacros

@DependencyClient
public struct GithubAPIClient: Sendable {
    /// This is an abstraction of the
    /// [List Repository Tags](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-tags)
    /// operation in the Github API.
    public var listRepositoryTags: @Sendable (ListRepositoryTags.Input) async throws -> ListRepositoryTags.Output = { _ in
        reportIssue("\(Self.self).listRepositoryTags not implemented")
        return .mock
    }

    /// This is an abstraction of the
    /// [Get Latest Release](https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#get-the-latest-release)
    /// operation in the Github API.
    public var getLatestRelease: @Sendable (GetLatestRelease.Input) async throws -> GetLatestRelease.Output = { _ in
        reportIssue("\(Self.self).getLatestRelease not implemented")
        return .mock
    }

    /// This is an abstraction of the
    /// [Get A Release By Tag Name](https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#get-a-release-by-tag-name)
    /// operation in the Github API.
    public var getReleaseByTagName: @Sendable (GetReleaseByTagName.Input) async throws -> GetReleaseByTagName.Output = { _ in
        reportIssue("\(Self.self).getReleaseByTagName not implemented")
        return .mock
    }

    /// This is an abstraction of the
    /// [Get Repository Content](https://docs.github.com/en/rest/repos/contents?apiVersion=2022-11-28#get-repository-content)
    /// operation in the Github API.
    public var getContent: @Sendable (GetContent.Input) async throws -> GetContent.Output = { _ in
        reportIssue("\(Self.self).getContent not implemented")
        return .mockFile
    }

    /// This is an abstraction of the
    /// [Get Repository](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#get-a-repository)
    /// operation in the Github API.
    public var getRepository: @Sendable (GetRepository.Input) async throws -> GetRepository.Output = { _ in
        reportIssue("\(Self.self).getRepository not implemented")
        return .mock
    }

    public enum Error: Swift.Error {
        case missingSourceArchiveURL(PackageInfo)
        case unexpectedContentType(String)
        case unexpectedOutputType(String)
        case contentIsNotAFile(info: PackageInfo, path: String)
        case contentUnsupportedEncoding(info: PackageInfo, path: String, encoding: String)
        case contentDecodingFailed(info: PackageInfo, path: String)

        public struct PackageInfo: Equatable, Sendable {
            public var owner: String
            public var repo: String
            public var version: String

            public init(owner: String, repo: String, version: String) {
                self.owner = owner
                self.repo = repo
                self.version = version
            }
        }
    }
}

extension GithubAPIClient {
    public static let mock = Self()
}

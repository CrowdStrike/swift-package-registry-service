import Dependencies
import Overture

extension GithubAPIClient {

    public static func test(
        repositoryListReleases: (@Sendable (RepositoryListReleases.Input) async throws -> RepositoryListReleases.Output)? = nil,
        listRepositoryTags: (@Sendable (ListRepositoryTags.Input) async throws -> ListRepositoryTags.Output)? = nil,
        getLatestRelease: (@Sendable (GetLatestRelease.Input) async throws -> GetLatestRelease.Output)? = nil,
        getReleaseByTagName: (@Sendable (GetReleaseByTagName.Input) async throws -> GetReleaseByTagName.Output)? = nil,
        getContent: (@Sendable (GetContent.Input) async throws -> GetContent.Output)? = nil
    ) -> Self {
        update(.mock) {
            if let repositoryListReleases {
                $0.repositoryListReleases = repositoryListReleases
            }
            if let listRepositoryTags {
                $0.listRepositoryTags = listRepositoryTags
            }
            if let getLatestRelease {
                $0.getLatestRelease = getLatestRelease
            }
            if let getReleaseByTagName {
                $0.getReleaseByTagName = getReleaseByTagName
            }
            if let getContent {
                $0.getContent = getContent
            }
        }
    }

    public static func testOutput(
        repositoryListReleasesOutput: RepositoryListReleases.Output? = nil,
        listRepositoryTagsOutput: ListRepositoryTags.Output? = nil,
        getReleaseByTagNameOutput: GetReleaseByTagName.Output? = nil,
        getContentOutput: GetContent.Output? = nil
    ) -> Self {
        update(.mock) {
            if let repositoryListReleasesOutput {
                $0.repositoryListReleases = { _ in repositoryListReleasesOutput }
            }
            if let listRepositoryTagsOutput {
                $0.listRepositoryTags = { _ in listRepositoryTagsOutput }
            }
            if let getReleaseByTagNameOutput {
                $0.getReleaseByTagName = { _ in getReleaseByTagNameOutput }
            }
            if let getContentOutput {
                $0.getContent = { _ in getContentOutput }
            }
        }
    }
}

import Foundation

extension GithubAPIClient {

    public enum RepositoryListReleases {
        public struct Input: Equatable, Sendable {
            public var owner: String
            public var repo: String
            public var perPage: Int?
            public var page: Int?

            public init(owner: String, repo: String, perPage: Int? = nil, page: Int? = nil) {
                self.owner = owner
                self.repo = repo
                self.perPage = perPage ?? Self.defaultPerPage
                self.page = page
            }

            static let defaultPerPage = 100
        }

        public enum Output: Equatable, Sendable {
            case ok(OKBody)
            case notFound
            case other(Int)

            public struct OKBody: Equatable, Sendable {
                public var linkHeader: String?
                public var releases: [Release]

                public init(linkHeader: String? = nil, releases: [Release]) {
                    self.linkHeader = linkHeader
                    self.releases = releases
                }
            }
        }
    }
}

extension GithubAPIClient.RepositoryListReleases.Input {

    public static let mock = Self(owner: "pointfreeco", repo: "swift-overture", perPage: 30, page: 1)
}

extension GithubAPIClient.RepositoryListReleases.Output {

    public static let mock: Self = .ok(.mock)
}

extension GithubAPIClient.RepositoryListReleases.Output.OKBody {

    public static let mock = Self(
        linkHeader: nil,
        releases: GithubAPIClient.Release.mocks
    )
}

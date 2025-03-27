import HTTPTypes

extension GithubAPIClient {

    public enum ListRepositoryTags {
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
            case other(HTTPResponse)
        }

        public struct OKBody: Equatable, Sendable {
            public var linkHeader: String?
            public var tags: [Tag]

            public init(linkHeader: String? = nil, tags: [Tag]) {
                self.linkHeader = linkHeader
                self.tags = tags
            }

            public struct Tag: Equatable, Sendable {
                public var name: String
                public var nodeId: String
                public var sha: String
                public var zipBallURL: String
                public var apiLexicalOrder: Int

                public init(name: String, nodeId: String, sha: String, zipBallURL: String, apiLexicalOrder: Int) {
                    self.name = name
                    self.nodeId = nodeId
                    self.sha = sha
                    self.zipBallURL = zipBallURL
                    self.apiLexicalOrder = apiLexicalOrder
                }
            }
        }
    }
}

extension GithubAPIClient.ListRepositoryTags.Input {
    public static let mock = Self(owner: "pointfreeco", repo: "swift-overture", perPage: 30, page: 1)
}

extension GithubAPIClient.ListRepositoryTags.Output {
    public static let mock: Self = .ok(
        .init(
            tags: [
                .init(
                    name: "0.5.0",
                    nodeId: "MDM6UmVmMTI4NzkxMTcwOnJlZnMvdGFncy8wLjUuMA==",
                    sha: "7977acd7597f413717058acc1e080731249a1d7e",
                    zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/refs/tags/0.5.0",
                    apiLexicalOrder: 0
                ),
                .init(
                    name: "0.4.0",
                    nodeId: "MDM6UmVmMTI4NzkxMTcwOnJlZnMvdGFncy8wLjQuMA==",
                    sha: "64d8a278b0d29ae73d45c329b506d4c407ba0704",
                    zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/refs/tags/0.4.0",
                    apiLexicalOrder: 1
                ),
                .init(
                    name: "0.3.1",
                    nodeId: "MDM6UmVmMTI4NzkxMTcwOnJlZnMvdGFncy8wLjMuMQ==",
                    sha: "d748c1351354ec34e591dd04662ddb58b7e01180",
                    zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/refs/tags/0.3.1",
                    apiLexicalOrder: 2
                ),
                .init(
                    name: "0.3.0",
                    nodeId: "MDM6UmVmMTI4NzkxMTcwOnJlZnMvdGFncy8wLjMuMA==",
                    sha: "084b113603c58286bac33c763f423bdabadafa6f",
                    zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/refs/tags/0.3.0",
                    apiLexicalOrder: 3
                ),
                .init(
                    name: "0.2.0",
                    nodeId: "MDM6UmVmMTI4NzkxMTcwOnJlZnMvdGFncy8wLjIuMA==",
                    sha: "2583a5815117e859b33bfc2d573f7fc47391d22b",
                    zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/refs/tags/0.2.0",
                    apiLexicalOrder: 4
                ),
                .init(
                    name: "0.1.0",
                    nodeId: "MDM6UmVmMTI4NzkxMTcwOnJlZnMvdGFncy8wLjEuMA==",
                    sha: "b907805523ca75a0c9fdaaf1bdf81b3fe3360ac7",
                    zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/refs/tags/0.1.0",
                    apiLexicalOrder: 5
                ),
            ]
        )
    )

    public static let empty: Self = .ok(.init(tags: []))
}

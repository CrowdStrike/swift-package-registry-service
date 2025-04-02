import Foundation

extension GithubAPIClient {

    public enum GetLatestRelease {
        public struct Input: Equatable, Sendable {
            public var owner: String
            public var repo: String

            public init(owner: String, repo: String) {
                self.owner = owner
                self.repo = repo
            }
        }

        public enum Output: Equatable, Sendable {
            case ok(Release)
            case other(Int)
        }
    }
}

extension GithubAPIClient.GetLatestRelease.Input {

    public static let mock = Self(owner: "pointfreeco", repo: "swift-overture")
}

extension GithubAPIClient.GetLatestRelease.Output {

    public static let mock: Self = .ok(.mock)
}

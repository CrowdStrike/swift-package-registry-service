import Foundation
import HTTPTypes

extension GithubAPIClient {
    public enum GetReleaseByTagName {
        public struct Input: Equatable, Sendable {
            public var owner: String
            public var repo: String
            public var tag: String

            public init(owner: String, repo: String, tag: String) {
                self.owner = owner
                self.repo = repo
                self.tag = tag
            }
        }

        public enum Output: Equatable, Sendable {
            case ok(Release)
            case notFound
            case other(HTTPResponse)
        }
    }
}

extension GithubAPIClient.GetReleaseByTagName.Input {
    public static let mock = Self(owner: "pointfreeco", repo: "swift-overture", tag: "0.5.0")
}

extension GithubAPIClient.GetReleaseByTagName.Output {
    public static let mock: Self = .ok(.mock)
}

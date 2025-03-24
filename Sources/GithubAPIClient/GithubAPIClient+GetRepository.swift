import Foundation

extension GithubAPIClient {

    public enum GetRepository {
        public struct Input: Equatable, Sendable {
            public var owner: String
            public var repo: String

            public init(owner: String, repo: String) {
                self.owner = owner
                self.repo = repo
            }
        }

        public enum Output: Equatable, Sendable {
            case ok(Repository)
            case movedPermanently
            case forbidden
            case notFound
            case other(Int)

        }
    }
}

extension GithubAPIClient.GetRepository.Input {

    public static let mock = Self(owner: "pointfreeco", repo: "swift-overture")
}

extension GithubAPIClient.GetRepository.Output {

    public static let mock: Self = .ok(.mock)
}

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
            case ok(OKBody)
            case movedPermanently
            case forbidden
            case notFound
            case other(Int)

            public struct OKBody: Equatable, Sendable {
                public var id: Int64
                public var nodeId: String
                public var owner: String?
                public var name: String
                public var htmlURL: String
                public var cloneURL: String
                public var sshURL: String

                public init(id: Int64, nodeId: String, owner: String?, name: String, htmlURL: String, cloneURL: String, sshURL: String) {
                    self.id = id
                    self.nodeId = nodeId
                    self.owner = owner
                    self.name = name
                    self.htmlURL = htmlURL
                    self.cloneURL = cloneURL
                    self.sshURL = sshURL
                }
            }
        }
    }
}

extension GithubAPIClient.GetRepository.Input {

    public static let mock = Self(owner: "pointfreeco", repo: "swift-overture")
}

extension GithubAPIClient.GetRepository.Output {

    public static let mock: Self = .ok(.mock)
}

extension GithubAPIClient.GetRepository.Output.OKBody {

    public static let mock = Self(
        id: 128791170,
        nodeId: "MDEwOlJlcG9zaXRvcnkxMjg3OTExNzA=",
        owner: "pointfreeco",
        name: "swift-overture",
        htmlURL: "https://github.com/pointfreeco/swift-overture",
        cloneURL: "https://github.com/pointfreeco/swift-overture.git",
        sshURL: "git@github.com:pointfreeco/swift-overture.git"
    )
}

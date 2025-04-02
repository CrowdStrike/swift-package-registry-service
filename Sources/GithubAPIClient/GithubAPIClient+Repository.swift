extension GithubAPIClient {

    public struct Repository: Equatable, Sendable {
        public var id: Int64
        public var nodeId: String
        public var owner: String
        public var name: String
        public var htmlURL: String
        public var cloneURL: String
        public var sshURL: String

        public init(id: Int64, nodeId: String, owner: String, name: String, htmlURL: String, cloneURL: String, sshURL: String) {
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

extension GithubAPIClient.Repository {

    public var packageID: String {
        "\(owner.lowercased()).\(name.lowercased())"
    }

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

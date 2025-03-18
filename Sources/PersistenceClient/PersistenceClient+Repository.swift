import Foundation

extension PersistenceClient {
    public struct RepositoriesFile: Equatable, Sendable, Codable {
        public var lastUpdatedAt: Date
        public var repositories: [Repository]

        public init(lastUpdatedAt: Date = .distantPast, repositories: [Repository] = []) {
            self.lastUpdatedAt = lastUpdatedAt
            self.repositories = repositories
        }
    }

    public struct Repository: Equatable, Sendable, Codable {
        /// This is the unique repository id from Github
        public var id: Int64
        /// This is the "organization" or "owner". Example: "pointfreeco"
        public var owner: String
        /// This is the name of the repo. Example: "swift-overture"
        public var name: String
        /// This is the HTTPS URL
        /// Example: https://github.com/pointfreeco/swift-overture.git
        public var cloneURL: String
        /// This is the SSH URL
        /// Example: git@github.com:pointfreeco/swift-overture.git
        public var sshURL: String
        /// This is the HTML URL, which is essentially the same as the HTTPS url, minus the ".git" prefix
        /// Example: https://github.com/pointfreeco/swift-overture
        public var htmlURL: String

        public init(id: Int64, owner: String, name: String, cloneURL: String, sshURL: String, htmlURL: String) {
            self.id = id
            self.owner = owner
            self.name = name
            self.cloneURL = cloneURL
            self.sshURL = sshURL
            self.htmlURL = htmlURL
        }
    }
}

extension PersistenceClient.RepositoriesFile {

    public static let mock = Self(
        lastUpdatedAt: ISO8601DateFormatter().date(from: "2025-03-16T19:23:47Z")!,
        repositories: PersistenceClient.Repository.mocks
    )
}

extension PersistenceClient.Repository {
    public static let mock = Self(
        id: 128791170,
        owner: "pointfreeco",
        name: "swift-overture",
        cloneURL: "https://github.com/pointfreeco/swift-overture.git",
        sshURL: "git@github.com:pointfreeco/swift-overture.git",
        htmlURL: "https://github.com/pointfreeco/swift-overture"
    )

    public static let mocks: [Self] = [
        .init(
            id: 128791170,
            owner: "pointfreeco",
            name: "swift-overture",
            cloneURL: "https://github.com/pointfreeco/swift-overture.git",
            sshURL: "git@github.com:pointfreeco/swift-overture.git",
            htmlURL: "https://github.com/pointfreeco/swift-overture"
        ),
        .init(
            id: 508795396,
            owner: "pointfreeco",
            name: "swift-clocks",
            cloneURL: "https://github.com/pointfreeco/swift-clocks.git",
            sshURL: "git@github.com:pointfreeco/swift-clocks.git",
            htmlURL: "https://github.com/pointfreeco/swift-clocks"
        ),
        .init(
            id: 543149227,
            owner: "pointfreeco",
            name: "swift-dependencies",
            cloneURL: "https://github.com/pointfreeco/swift-dependencies.git",
            sshURL: "git@github.com:pointfreeco/swift-dependencies.git",
            htmlURL: "https://github.com/pointfreeco/swift-dependencies"
        ),
    ]
}

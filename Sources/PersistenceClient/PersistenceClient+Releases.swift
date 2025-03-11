import Foundation

extension PersistenceClient {

    public struct Release: Equatable, Sendable, Codable {
        public var owner: String
        public var repo: String
        public var tagName: String
        public var id: Int
        public var name: String?
        public var createdAt: Date?
        public var publishedAt: Date?
        public var semanticVersion: String?
        public var zipBallURL: String?
        public var fromTag: Bool

        public init(
            owner: String,
            repo: String,
            tagName: String,
            id: Int,
            name: String? = nil,
            createdAt: Date? = nil,
            publishedAt: Date? = nil,
            semanticVersion: String? = nil,
            zipBallURL: String? = nil,
            fromTag: Bool = false
        ) {
            self.owner = owner
            self.repo = repo
            self.tagName = tagName
            self.id = id
            self.name = name
            self.createdAt = createdAt
            self.publishedAt = publishedAt
            self.semanticVersion = semanticVersion
            self.zipBallURL = zipBallURL
            self.fromTag = fromTag
        }
    }
}

extension PersistenceClient.Release: Comparable {

    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs.createdAt, rhs.createdAt) {
        case (.none, .none): false
        case (.some, .none): false
        case (.none, .some): true
        case let (.some(lhsDate), .some(rhsDate)): lhsDate < rhsDate
        }
    }
}

extension PersistenceClient.Release {

    public static let mock = Self(
        owner: "pointfreeco",
        repo: "swift-overture",
        tagName: "0.5.0",
        id: 16362611,
        name: "The Boring Swift 5 Release",
        createdAt: ISO8601DateFormatter().date(from: "2019-03-26T18:04:46Z"),
        publishedAt: ISO8601DateFormatter().date(from: "2019-03-26T18:04:46Z"),
        semanticVersion: "0.5.0",
        zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.5.0"
    )

    public static let mocks: [Self] = [
        .init(
            owner: "pointfreeco",
            repo: "swift-overture",
            tagName: "0.5.0",
            id: 16362611,
            name: "The Boring Swift 5 Release",
            createdAt: ISO8601DateFormatter().date(from: "2019-03-26T15:19:07Z"),
            publishedAt: ISO8601DateFormatter().date(from: "2019-03-26T18:04:46Z"),
            semanticVersion: "0.5.0",
            zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.5.0"
        ),
        .init(
            owner: "pointfreeco",
            repo: "swift-overture",
            tagName: "0.4.0",
            id: 15981279,
            name: "0.4.0",
            createdAt: ISO8601DateFormatter().date(from: "2019-03-07T20:29:39Z"),
            publishedAt: ISO8601DateFormatter().date(from: "2019-03-07T20:32:30Z"),
            semanticVersion: "0.4.0",
            zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.4.0"
        ),
        .init(
            owner: "pointfreeco",
            repo: "swift-overture",
            tagName: "0.3.1",
            id: 13926079,
            name: "Publicize `zip(with:)`s!",
            createdAt: ISO8601DateFormatter().date(from: "2018-10-23T10:48:07Z"),
            publishedAt: ISO8601DateFormatter().date(from: "2018-11-09T17:55:52Z"),
            semanticVersion: "0.3.1",
            zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.3.1"
        ),
        .init(
            owner: "pointfreeco",
            repo: "swift-overture",
            tagName: "0.3.0",
            id: 12459714,
            name: "Now with Zip",
            createdAt: ISO8601DateFormatter().date(from: "2018-08-22T18:11:08Z"),
            publishedAt: ISO8601DateFormatter().date(from: "2018-08-22T18:13:55Z"),
            semanticVersion: "0.3.0",
            zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.3.0"
        ),
        .init(
            owner: "pointfreeco",
            repo: "swift-overture",
            tagName: "0.2.0",
            id: 11006052,
            name: "Now with Functional Setters",
            createdAt: ISO8601DateFormatter().date(from: "2018-05-15T12:59:39Z"),
            publishedAt: ISO8601DateFormatter().date(from: "2018-05-15T13:03:26Z"),
            semanticVersion: "0.2.0",
            zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.2.0"
        ),
        .init(
            owner: "pointfreeco",
            repo: "swift-overture",
            tagName: "0.1.0",
            id: 11006368,
            name: "Function Composition without Operators",
            createdAt: ISO8601DateFormatter().date(from: "2018-05-15T04:00:29Z"),
            publishedAt: ISO8601DateFormatter().date(from: "2018-05-15T13:19:13Z"),
            semanticVersion: "0.1.0",
            zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.1.0"
        ),
    ]
}

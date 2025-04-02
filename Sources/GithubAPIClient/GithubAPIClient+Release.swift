import Foundation

extension GithubAPIClient {
    public struct Release: Equatable, Sendable {
        public var createdAt: Date?
        public var draft: Bool
        public var id: Int
        public var name: String?
        public var prerelease: Bool
        public var publishedAt: Date?
        public var tagName: String
        public var zipBallURL: String?

        public init(
            createdAt: Date? = nil,
            draft: Bool = false,
            id: Int,
            name: String? = nil,
            prerelease: Bool = false,
            publishedAt: Date? = nil,
            tagName: String,
            zipBallURL: String? = nil
        ) {
            self.createdAt = createdAt
            self.draft = draft
            self.id = id
            self.name = name
            self.prerelease = prerelease
            self.publishedAt = publishedAt
            self.tagName = tagName
            self.zipBallURL = zipBallURL
        }
    }
}

extension GithubAPIClient.Release {

    public static let mock = Self(
        createdAt: ISO8601DateFormatter().date(from: "2019-03-26T18:04:46Z"),
        id: 16362611,
        name: "The Boring Swift 5 Release",
        publishedAt: ISO8601DateFormatter().date(from: "2019-03-26T18:04:46Z"),
        tagName: "0.5.0",
        zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.5.0"
    )

    public static let mocks: [Self] = [
        .init(
            createdAt: ISO8601DateFormatter().date(from: "2019-03-26T15:19:07Z"),
            id: 16362611,
            name: "The Boring Swift 5 Release",
            publishedAt: ISO8601DateFormatter().date(from: "2019-03-26T18:04:46Z"),
            tagName: "0.5.0",
            zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.5.0"
        ),
        .init(
            createdAt: ISO8601DateFormatter().date(from: "2019-03-07T20:29:39Z"),
            id: 15981279,
            name: "0.4.0",
            publishedAt: ISO8601DateFormatter().date(from: "2019-03-07T20:32:30Z"),
            tagName: "0.4.0",
            zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.4.0"
        ),
        .init(
            createdAt: ISO8601DateFormatter().date(from: "2018-10-23T10:48:07Z"),
            id: 13926079,
            name: "Publicize `zip(with:)`s!",
            publishedAt: ISO8601DateFormatter().date(from: "2018-11-09T17:55:52Z"),
            tagName: "0.3.1",
            zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.3.1"
        ),
        .init(
            createdAt: ISO8601DateFormatter().date(from: "2018-08-22T18:11:08Z"),
            id: 12459714,
            name: "Now with Zip",
            publishedAt: ISO8601DateFormatter().date(from: "2018-08-22T18:13:55Z"),
            tagName: "0.3.0",
            zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.3.0"
        ),
        .init(
            createdAt: ISO8601DateFormatter().date(from: "2018-05-15T12:59:39Z"),
            id: 11006052,
            name: "Now with Functional Setters",
            publishedAt: ISO8601DateFormatter().date(from: "2018-05-15T13:03:26Z"),
            tagName: "0.2.0",
            zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.2.0"
        ),
        .init(
            createdAt: ISO8601DateFormatter().date(from: "2018-05-15T04:00:29Z"),
            id: 11006368,
            name: "Function Composition without Operators",
            publishedAt: ISO8601DateFormatter().date(from: "2018-05-15T13:19:13Z"),
            tagName: "0.1.0",
            zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.1.0"
        ),
    ]
}

import APIUtilities
import Foundation

extension PersistenceClient {

    public struct TagFile: Equatable, Sendable {
        public var lastUpdatedAt: Date
        public var tags: [Tag]
        public var versionToTagName: [Version: String]

        public init(
            lastUpdatedAt: Date = .distantPast,
            tags: [Tag] = [],
            versionToTagName: [Version: String] = [:]
        ) {
            self.lastUpdatedAt = lastUpdatedAt
            self.tags = tags
            self.versionToTagName = versionToTagName
        }

        enum CodingKeys: String, CodingKey {
            case lastUpdatedAt
            case tags
            case versionToTagName
        }
    }

    public struct Tag: Equatable, Sendable, Codable {
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

// Custom implementation of Decodable. For some reason, the compiler's
// implementation produces a JSON array for versionToTagName instead of a JSON dictionary.
extension PersistenceClient.TagFile: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lastUpdatedAt, forKey: .lastUpdatedAt)
        try container.encode(tags, forKey: .tags)
        let stringVersionToTagNameMap = versionToTagName.reduce(into: [String: String]()) { $0[$1.0.description] = $1.1 }
        try container.encode(stringVersionToTagNameMap, forKey: .versionToTagName)
    }
}

extension PersistenceClient.TagFile: Decodable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastUpdatedAt = try container.decode(Date.self, forKey: .lastUpdatedAt)
        tags = try container.decode([PersistenceClient.Tag].self, forKey: .tags)
        let stringVersionToTagNameMap = try container.decode([String: String].self, forKey: .versionToTagName)
        versionToTagName = stringVersionToTagNameMap.reduce(into: [Version: String]()) {
            if let version = Version($1.0) {
                $0[version] = $1.1
            }
        }
    }
}

extension PersistenceClient.TagFile {

    public static let mock = Self(
        lastUpdatedAt: Date.distantPast,
        tags: PersistenceClient.Tag.mocks,
        versionToTagName: [
            .init(0, 5, 0): "0.5.0",
            .init(0, 4, 0): "0.4.0",
            .init(0, 3, 1): "0.3.1",
            .init(0, 3, 0): "0.3.0",
            .init(0, 2, 0): "0.2.0",
            .init(0, 1, 0): "0.1.0",
        ]
    )
}

extension PersistenceClient.Tag {

    public static let mock: Self = .init(
        name: "0.5.0",
        nodeId: "MDM6UmVmMTI4NzkxMTcwOnJlZnMvdGFncy8wLjUuMA==",
        sha: "7977acd7597f413717058acc1e080731249a1d7e",
        zipBallURL: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/refs/tags/0.5.0",
        apiLexicalOrder: 0
    )

    public static let mocks: [Self] = [
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
}

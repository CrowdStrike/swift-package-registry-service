import APIUtilities
import Foundation
import Vapor

struct FetchReleaseMetadata: Content {
    var id: String
    var version: String
    var resources: [Resource]
    var metadata: Metadata
    var publishedAt: Date?

    struct Resource: Content {
        var name: String
        var type: String
        var checksum: String
        var signing: Signing?

        struct Signing: Content {
            var signatureBase64Encoded: String
            var signatureFormat: String
        }

        static let sourceArchive = "source-archive"
        static let applicationZip = "application/zip"

        static func sourceArchive(withChecksum checksum: String) -> Self {
            .init(name: sourceArchive, type: applicationZip, checksum: checksum)
        }
    }

    struct Metadata: Content {
        var author: Author?
        var description: String?
        var licenseURL: String?
        var originalPublicationTime: Date?
        var readmeURL: String?
        var repositoryURLs: [String]?

        struct Author: Content {
            var name: String
            var email: String?
            var description: String?
            var organization: Organization?
            var url: String?

            struct Organization: Content {
                var name: String
                var email: String?
                var description: String?
                var url: String?
            }
        }

        static func metadata(scope: String, name: String) -> Self {
            .init(
                repositoryURLs: [
                    "https://github.com/\(scope)/\(name)",
                    "https://github.com/\(scope)/\(name).git",
                    "git@github.com:\(scope)/\(name).git",
                ]
            )
        }
    }
}

extension FetchReleaseMetadata: AsyncResponseEncodable {

    func encodeResponse(for request: Request) async throws -> Response {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/json")
        headers.add(name: .contentVersion, value: SwiftRegistryAcceptHeader.Version.v1.rawValue)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .default
        let data = try encoder.encode(self)
        return .init(status: .ok, headers: headers, body: .init(data: data))
    }
}

extension FetchReleaseMetadata {
    static let mock = Self(
        id: "pointfreeco.swift-overture",
        version: "0.5.0",
        resources: [
            .init(
                name: "source-archive",
                type: "application/zip",
                checksum: "13aedbe3a79154ef848290444ac754c5cf9fee9283f46a3a43645004a912063f"
            )
        ],
        metadata: .init(
            repositoryURLs: [
                "https://github.com/pointfreeco/swift-overture",
                "https://github.com/pointfreeco/swift-overture.git",
                "git@github.com:pointfreeco/swift-overture.git",
            ]
        ),
        publishedAt: ISO8601DateFormatter().date(from: "2019-03-26T18:04:46Z")
    )
}

import Foundation

struct PackageReleaseMetadata: Equatable, Codable, Sendable {
    var packageScope: String
    var packageName: String
    var packageVersion: String
    var tagName: String
    var publishedAt: Date?
    var zipBallURL: String
    var cacheFileName: String
    var checksum: String
}

extension PackageReleaseMetadata {
    var idText: String {
        "\"\(packageScope).\(packageName)\" \(packageVersion)"
    }
}

import Fluent
import Foundation
import Vapor

final class PackageRelease: Model, @unchecked Sendable {
    static let schema = "package_releases"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "package_scope")
    var packageScope: String

    @Field(key: "package_name")
    var packageName: String

    @Field(key: "package_version")
    var packageVersion: String

    @Field(key: "tag_name")
    var tagName: String

    @OptionalField(key: "published_at")
    var publishedAt: Date?

    @Field(key: "zip_ball_url")
    var zipBallURL: String

    @Field(key: "cache_file_name")
    var cacheFileName: String

    @Field(key: "checksum")
    var checksum: String

    init() { }

    init(
        id: UUID? = nil,
        packageScope: String,
        packageName: String,
        packageVersion: String,
        tagName: String,
        publishedAt: Date?,
        zipBallURL: String,
        cacheFileName: String,
        checksum: String
    ) {
        self.id = id
        self.packageScope = packageScope
        self.packageName = packageName
        self.packageVersion = packageVersion
        self.tagName = tagName
        self.publishedAt = publishedAt
        self.zipBallURL = zipBallURL
        self.cacheFileName = cacheFileName
        self.checksum = checksum
    }
}

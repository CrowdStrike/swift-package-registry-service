import Fluent
import Foundation
import Vapor

final class Manifest: Model, @unchecked Sendable {
    static let schema = "manifests"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "package_scope")
    var packageScope: String

    @Field(key: "package_name")
    var packageName: String

    @Field(key: "package_version")
    var packageVersion: String

    @OptionalField(key: "swift_version")
    var swiftVersion: String?

    @Field(key: "swift_tools_version")
    var swiftToolsVersion: String

    @Field(key: "cache_file_name")
    var cacheFileName: String

    init() { }

    init(
        id: UUID? = nil,
        packageScope: String,
        packageName: String,
        packageVersion: String,
        swiftVersion: String? = nil,
        swiftToolsVersion: String,
        cacheFileName: String
    ) {
        self.id = id
        self.packageScope = packageScope
        self.packageName = packageName
        self.packageVersion = packageVersion
        self.swiftVersion = swiftVersion
        self.swiftToolsVersion = swiftToolsVersion
        self.cacheFileName = cacheFileName
    }
}

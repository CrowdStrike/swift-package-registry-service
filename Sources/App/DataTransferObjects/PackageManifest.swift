struct PackageManifest: Equatable, Codable, Sendable {
    var packageScope: String
    var packageName: String
    var packageVersion: String
    var swiftVersion: String?
    var swiftToolsVersion: String

    init(
        packageScope: String,
        packageName: String,
        packageVersion: String,
        swiftVersion: String? = nil,
        swiftToolsVersion: String
    ) {
        self.packageScope = packageScope
        self.packageName = packageName
        self.packageVersion = packageVersion
        self.swiftVersion = swiftVersion
        self.swiftToolsVersion = swiftToolsVersion
    }
}

extension PackageManifest {

    var fileName: String {
        var name = "Package"
        if let swiftVersion {
            name += "@swift-\(swiftVersion)"
        }
        name += ".swift"
        return name
    }

    var hasVersion: Bool { swiftVersion != nil }
    var isUnversioned: Bool { swiftVersion == nil }
}

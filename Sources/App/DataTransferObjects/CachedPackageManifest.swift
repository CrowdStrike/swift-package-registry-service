import Foundation

struct CachedPackageManifest: Equatable, Codable, Sendable {
    var packageManifest: PackageManifest
    var cacheFileName: String

    init(packageManifest: PackageManifest, cacheFileName: String) {
        self.packageManifest = packageManifest
        self.cacheFileName = cacheFileName
    }
}

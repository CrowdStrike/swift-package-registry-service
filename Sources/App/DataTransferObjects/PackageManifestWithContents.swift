import NIOCore

struct PackageManifestWithContents: Equatable, Codable, Sendable {
    var packageManifest: PackageManifest
    var contents: ByteBuffer

    init(packageManifest: PackageManifest, contents: ByteBuffer) {
        self.packageManifest = packageManifest
        self.contents = contents
    }
}

import NIOCore

extension PersistenceClient {

    public struct Manifest: Equatable, Sendable, Codable {
        public var fileName: String
        public var swiftVersion: String?
        public var swiftToolsVersion: String?
        public var contents: ByteBuffer?

        public init(
            fileName: String,
            swiftVersion: String? = nil,
            swiftToolsVersion: String? = nil,
            contents: ByteBuffer? = nil
        ) {
            self.fileName = fileName
            self.swiftVersion = swiftVersion
            self.swiftToolsVersion = swiftToolsVersion
            self.contents = contents
        }

        public var hasVersion: Bool { swiftVersion != nil }
        public var isUnversioned: Bool { swiftVersion == nil }
        public var hasContents: Bool { contents != nil }

        enum CodingKeys: String, CodingKey {
            case fileName
            case swiftVersion
            case swiftToolsVersion
        }
    }

    public struct ManifestDirectory: Equatable, Sendable, Codable {
        public var manifests: [Manifest]

        public init(manifests: [Manifest] = []) {
            self.manifests = manifests
        }
    }
}

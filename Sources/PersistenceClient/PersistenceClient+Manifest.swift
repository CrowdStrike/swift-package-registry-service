import NIOCore

extension PersistenceClient {

    public struct Manifest: Equatable, Sendable, Codable {
        /// This is the name of the package manifest file, without any path. Examples: `Package.swift`, `Package@swift-6.0.swift`
        public var fileName: String
        /// The full path to the cached manifest file
        public var cachedFilePath: String?
        /// If this is a version-specific package manifest, then this is the swift version. Otherwise, it is `nil`.
        /// Example: if the manifest file name is `Package@swift-6.0.swift`, then this would be `6.0`
        public var swiftVersion: String?
        /// The swift-tools-version at the top of the package manifest
        public var swiftToolsVersion: String?
        /// The contents of the package manifest file. Since we use the Github API Get Contents method
        /// to fetch the manifest, then we already have fetched the entire contents of the file into memory.
        /// So it is convenient when writing to the `PersistenceClient` to include the contents.
        /// When we are reading from the `PersistenceClient`, we do not include the contents,
        /// because we can stream that directly from the cached file.
        public var contents: ByteBuffer?

        public init(
            fileName: String,
            cachedFilePath: String? = nil,
            swiftVersion: String? = nil,
            swiftToolsVersion: String? = nil,
            contents: ByteBuffer? = nil
        ) {
            self.fileName = fileName
            self.cachedFilePath = cachedFilePath
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

extension PersistenceClient.Manifest {

    public var withoutContents: Self {
        .init(
            fileName: fileName,
            cachedFilePath: cachedFilePath,
            swiftVersion: swiftVersion,
            swiftToolsVersion: swiftToolsVersion,
            contents: nil
        )
    }

    public var withoutCachedFilePath: Self {
        .init(
            fileName: fileName,
            cachedFilePath: nil,
            swiftVersion: swiftVersion,
            swiftToolsVersion: swiftToolsVersion,
            contents: contents
        )
    }

    public func withCachedFilePath(_ cachedFilePath: String) -> Self {
        .init(
            fileName: fileName,
            cachedFilePath: cachedFilePath,
            swiftVersion: swiftVersion,
            swiftToolsVersion: swiftToolsVersion,
            contents: contents
        )
    }
}

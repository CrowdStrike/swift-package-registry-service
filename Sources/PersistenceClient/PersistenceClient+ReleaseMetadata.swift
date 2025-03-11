import APIUtilities
import Foundation

extension PersistenceClient {

    public struct ReleaseMetadata: Equatable, Sendable, Codable {
        public var checksum: String
        public var tag: Tag
        public var version: Version

        public init(checksum: String, tag: Tag, version: Version) {
            self.checksum = checksum
            self.tag = tag
            self.version = version
        }
    }
}

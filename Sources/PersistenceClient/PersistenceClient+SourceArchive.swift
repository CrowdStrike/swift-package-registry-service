import NIOCore

extension PersistenceClient {

    public struct SourceArchive: Equatable, Sendable, Codable {
        public var fileName: String

        public init(fileName: String) {
            self.fileName = fileName
        }
    }
}

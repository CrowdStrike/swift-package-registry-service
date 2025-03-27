import NIOCore

extension PersistenceClient {

    public struct SourceArchive: Equatable, Sendable, Codable {
        public var fileName: String
        public var byteBuffer: ByteBuffer

        public init(fileName: String, byteBuffer: ByteBuffer) {
            self.fileName = fileName
            self.byteBuffer = byteBuffer
        }
    }
}

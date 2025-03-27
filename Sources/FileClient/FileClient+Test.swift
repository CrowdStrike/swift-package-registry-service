import NIOCore
import Overture

extension FileClient {

    public static func test(
        readFile: (@Sendable (_ path: String) async throws -> ByteBuffer)? = nil,
        writeFile: (@Sendable (_ buffer: ByteBuffer, _ path: String) async throws -> Void)? = nil
    ) -> Self {
        update(.mock) {
            if let readFile {
                $0.readFile = readFile
            }
            if let writeFile {
                $0.writeFile = writeFile
            }
        }
    }
}

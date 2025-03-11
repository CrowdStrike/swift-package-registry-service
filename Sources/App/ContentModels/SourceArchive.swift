import APIUtilities
import NIOCore
import Vapor

struct SourceArchive {
    var contentDispositionHeaderValue: String?
    var value: ByteBuffer
}

extension SourceArchive: AsyncResponseEncodable {
    func encodeResponse(for request: Request) async throws -> Response {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/zip")
        headers.add(name: .contentVersion, value: SwiftRegistryAcceptHeader.Version.v1.rawValue)
        if let contentDispositionHeaderValue {
            headers.add(name: .contentDisposition, value: contentDispositionHeaderValue)
        }
        return .init(status: .ok, headers: headers, body: .init(buffer: value))
    }
}

extension SourceArchive {
    static let mock = Self(
        contentDispositionHeaderValue: "attachment; filename=\"mock.zip\"",
        value: .init(repeating: 0, count: 1024)
    )
}

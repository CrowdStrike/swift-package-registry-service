import AsyncHTTPClient
import FileClient
import Foundation
import HTTPStreamClient
import NIOHTTP1
import NIOCore
import Vapor

extension ChecksumClient {

    public static func live(
        httpStreamClient: HTTPStreamClient,
        fileClient: FileClient,
        getHashAlgorithm: @escaping @Sendable () -> HashAlgorithm = { SHA256() }
    ) -> Self {
        Self(
            computeChecksum: { input in
                let logger = Logger(label: "ChecksumClient")
                do {
                    var request = HTTPClientRequest(url: input.urlString)
                    request.headers.add(
                        name: "User-Agent",
                        value: "async-http-client/1.24.2"
                    )
                    if !input.apiToken.isEmpty {
                        request.headers.add(
                            name: "Authorization",
                            value: "Bearer \(input.apiToken)"
                        )
                    }
                    let response = try await httpStreamClient.execute(request)
                    logger.debug("HTTP Response: \(response)")

                    // If defined, the content-length headers announces the size of the body
                    let expectedBytes = response.headers.first(name: "Content-Length").flatMap(Int.init)
                    logger.debug("Content-Length: \(String(describing: expectedBytes))")

                    guard response.status == .ok else {
                        return .httpError(Int(response.status.code))
                    }

                    var receivedBytes = 0
                    var hashAlgorithm = getHashAlgorithm()
                    for try await buffer in response.body {
                        // Update the receivedBytes count
                        receivedBytes += buffer.readableBytes
                        // Update the hash
                        hashAlgorithm.hash(Array<UInt8>(buffer: buffer))
                    }
                    logger.debug("Received total of \(receivedBytes) bytes")
                    let hashBytes = hashAlgorithm.finalize()

                    return .ok(.init(checksum: hashBytes.hexadecimalRepresentation))
                } catch {
                    logger.error("Download error: \(error)")
                    throw error
                }
            },
            computeFileChecksum: { path in
                // Hash the whole file in one go.
                // TODO: improve performance by hashing chunk-by-chunk
                let fileBytes = try await fileClient.readFile(path: path)
                var hashAlgorithm = getHashAlgorithm()
                hashAlgorithm.hash(Array<UInt8>(buffer: fileBytes))
                let hashBytes = hashAlgorithm.finalize()
                return hashBytes.hexadecimalRepresentation
            }
        )
    }

    public enum Error: Swift.Error {
        case httpError(Int)
    }
}

extension Array where Element == UInt8 {
    var hexadecimalRepresentation: String {
        reduce("") {
            var str = String($1, radix: 16)
            // The above method does not do zero padding.
            if str.count == 1 {
                str = "0" + str
            }
            return $0 + str
        }
    }
}

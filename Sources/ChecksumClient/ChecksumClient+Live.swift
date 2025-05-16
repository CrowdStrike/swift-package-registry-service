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

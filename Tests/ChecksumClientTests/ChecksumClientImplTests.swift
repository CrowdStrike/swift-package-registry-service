@testable import AsyncHTTPClient
@testable import ChecksumClient
import CryptoKit
import Foundation
import HTTPStreamClient
import NIOCore
import NIOHTTP1
import Testing

struct ChecksumClientTests {

    @Test func cryptoKitSHA256() throws {
        let url = try #require(Bundle.module.url(forResource: "swift-overture-0.5.0", withExtension: "zip"))
        let contents = try Data(contentsOf: url)

        var hashFunction = CryptoKitSHA256()

        // Break up into 1k chunks
        let chunkSize = 1024
        var lowerBound = 0
        var upperBound = 0
        while lowerBound < contents.count {
            upperBound = min(lowerBound + chunkSize, contents.count)
            hashFunction.hash(Array(contents[lowerBound..<upperBound]))
            lowerBound = upperBound
        }
        let hash = hashFunction.finalize()
        let hex = hash.hexadecimalRepresentation

        #expect(hex == "06bc2e1e4f22b40bc2c4c045d7559bcceb94e684cd32ebb295eee615890d724e")
    }

    @Test func checksumClient() async throws {
        let url = try #require(Bundle.module.url(forResource: "swift-overture-0.5.0", withExtension: "zip"))
        let contents = try Data(contentsOf: url)

        let httpClientResponse = HTTPClientResponse(
            version: .http1_1,
            status: .ok,
            headers: .init([("Content-Length", "\(contents.count)")]),
            body: .bytes(.init(data: contents))
        )
        let checkSumClient = ChecksumClient.live(
            httpStreamClient: .test(response: httpClientResponse),
            fileClient: .mock,
            getHashAlgorithm: { CryptoKitSHA256() }
        )
        let checksum = try await checkSumClient.computeChecksum(.mock)
        #expect(checksum.checksum == "06bc2e1e4f22b40bc2c4c045d7559bcceb94e684cd32ebb295eee615890d724e")
    }

    @Test func checksumClientChunks() async throws {
        let url = try #require(Bundle.module.url(forResource: "swift-overture-0.5.0", withExtension: "zip"))
        let contents = try Data(contentsOf: url)

        // Create an HTTPClientResponse with 1k chunks
        let httpClientResponse = HTTPClientResponse(
            version: .http1_1,
            status: .ok,
            headers: .init([("Content-Length", "\(contents.count)")]),
            body: .stream(contents.byteBufferChunks(size: 1024).async)
        )
        let checkSumClient = ChecksumClient.live(
            httpStreamClient: .test(response: httpClientResponse),
            fileClient: .mock,
            getHashAlgorithm: { CryptoKitSHA256() }
        )
        let checksum = try await checkSumClient.computeChecksum(.mock)
        #expect(checksum.checksum == "06bc2e1e4f22b40bc2c4c045d7559bcceb94e684cd32ebb295eee615890d724e")
    }
}

extension Data {
    func byteBufferChunks(size: Int) -> [ByteBuffer] {
        var output = [ByteBuffer]()
        var lowerBound = 0
        while lowerBound < count {
            let upperBound = Swift.min(lowerBound + size, count)
            output.append(.init(data: self[lowerBound..<upperBound]))
            lowerBound = upperBound
        }
        return output
    }
}

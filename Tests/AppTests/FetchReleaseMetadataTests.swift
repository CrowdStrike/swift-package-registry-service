@testable import App
import ConcurrencyExtras
import GithubAPIClient
import ChecksumClient
import HTTPStreamClient
import Overture
import Testing
import VaporTesting

@Suite("fetchReleaseMetadata Tests")
struct FetchReleaseMetadataTests {

    @Test func invalidPackageScopeResultsInBadRequest() async throws {
        try await testApp { app in
            // Use 41 characters in the package scope - 1 character too many
            try await app.testing().test(.GET, "1234567890123456789012345678901234567890/swift-clocks/0.1.0") { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func invalidPackageNameResultsInBadRequest() async throws {
        try await testApp { app in
            // Use two successive hyphens in package name
            try await app.testing().test(.GET, "pointfreeco/swift--clocks/0.1.0") { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func invalidContentVersionResultsInBadRequest() async throws {
        try await testApp { app in
            // Send version 3 in the Accept header
            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.1.0", headers: ["Accept": "application/vnd.swift.registry.v3+json"]) { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func unknownMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send unknown media type
            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.1.0", headers: ["Accept": "application/vnd.swift.registry.v1+foobar"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

    @Test func unexpectedSwiftMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send "swift" media type
            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.1.0", headers: ["Accept": "application/vnd.swift.registry.v1+swift"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

//    @Test func canAppendJSONExtension() async throws {
//        let client: GithubAPIClient = .test(
//            getReleaseByTagName: { input in
//                #expect(input.owner == "pointfreeco")
//                #expect(input.repo == "swift-clocks")
//                #expect(input.tag == "0.1.0")
//                return .mock
//            }
//        )
//        let checksumClient: ChecksumClient = update(.mock) {
//            $0.computeChecksum = { _ in .ok(.init(checksum: "123456")) }
//        }
//        try await testApp(githubAPIClient: client, checksumClient: checksumClient) { app in
//            // Append .json to the package name. Verify that it does not cause failure.
//            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.1.0.json", headers: ["Accept": "application/vnd.swift.registry.v1+json"]) { res in
//                #expect(res.status == .ok)
//            }
//        }
//    }
//
//    @Test func noZipSuffixOnVersionResultsInGetReleaseByTagNameRequest() async throws {
//        let client: GithubAPIClient = .test(
//            getReleaseByTagName: { input in
//                #expect(input.owner == "pointfreeco")
//                #expect(input.repo == "swift-clocks")
//                #expect(input.tag == "0.1.0")
//                return .mock
//            }
//        )
//        let checksumClient: ChecksumClient = update(.mock) {
//            $0.computeChecksum = { _ in .ok(.init(checksum: "123456")) }
//        }
//        try await testApp(githubAPIClient: client, checksumClient: checksumClient) { app in
//            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.1.0", headers: ["Accept": "application/vnd.swift.registry.v1+json"]) { res in
//                #expect(res.status == .ok)
//            }
//        }
//    }
//
//    @Test func zipSuffixResultsInStreamClientRequest() async throws {
//        // Read the resource file into memory
//        let url = try #require(Bundle.module.url(forResource: "swift-overture-0.5.0", withExtension: "zip"))
//        let contents = try Data(contentsOf: url)
//
//        let client: GithubAPIClient = .test(
//            getReleaseByTagName: { input in
//                #expect(input.owner == "pointfreeco")
//                #expect(input.repo == "swift-overture")
//                #expect(input.tag == "0.5.0")
//                return .mock
//            }
//        )
//        let httpClient = HTTPStreamClient(
//            execute: { _ in
//                .init(status: .ok, headers: HTTPHeaders(), body: .bytes(.init(data: contents)))
//            }
//        )
//        try await testApp(githubAPIClient: client, httpStreamClient: httpClient) { app in
//            try await app.testing().test(.GET, "pointfreeco/swift-overture/0.5.0.zip", headers: ["Accept": "application/vnd.swift.registry.v1+zip"]) { res in
//                #expect(res.status == .ok)
//            }
//        }
//    }
}

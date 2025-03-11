@testable import App
import ConcurrencyExtras
import GithubAPIClient
import ChecksumClient
import HTTPStreamClient
import Testing
import VaporTesting

@Suite("downloadSourceArchive Tests")
struct DownloadSourceArchiveTests {

    @Test func invalidPackageScopeResultsInBadRequest() async throws {
        try await testApp { app in
            // Use 41 characters in the package scope - 1 character too many
            try await app.testing().test(.GET, "1234567890123456789012345678901234567890/swift-clocks/0.5.0.zip") { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func invalidPackageNameResultsInBadRequest() async throws {
        try await testApp { app in
            // Use two successive hyphens in package name
            try await app.testing().test(.GET, "pointfreeco/swift--clocks/0.5.0.zip") { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func invalidContentVersionResultsInBadRequest() async throws {
        try await testApp { app in
            // Send version 3 in the Accept header
            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.5.0.zip", headers: ["Accept": "application/vnd.swift.registry.v3+zip"]) { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func unknownMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send unknown media type
            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.5.0.zip", headers: ["Accept": "application/vnd.swift.registry.v1+foobar"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

    @Test func unexpectedSwiftMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send "swift" media type
            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.5.0.zip", headers: ["Accept": "application/vnd.swift.registry.v1+swift"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

    @Test func unexpectedJsonMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send "json" media type
            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.5.0.zip", headers: ["Accept": "application/vnd.swift.registry.v1+json"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

//    @Test func zipBallURLIsRequestedInHTTPStreamClient() async throws {
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
//            execute: { input in
//                #expect(input.url == GithubAPIClient.Release.mock.zipBallURL)
//                return .init(status: .ok, headers: HTTPHeaders(), body: .bytes(.init(data: contents)))
//            }
//        )
//        try await testApp(githubAPIClient: client, httpStreamClient: httpClient) { app in
//            try await app.testing().test(.GET, "pointfreeco/swift-overture/0.5.0.zip", headers: ["Accept": "application/vnd.swift.registry.v1+zip"]) { res in
//                #expect(res.status == .ok)
//            }
//        }
//    }
//
//    @Test func contentTypeIsApplicationZip() async throws {
//        // Read the resource file into memory
//        let url = try #require(Bundle.module.url(forResource: "swift-overture-0.5.0", withExtension: "zip"))
//        let contentsData = try Data(contentsOf: url)
//        let contentsByteBuffer = ByteBuffer(data: contentsData)
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
//            execute: { input in
//                return .init(status: .ok, headers: HTTPHeaders(), body: .bytes(contentsByteBuffer))
//            }
//        )
//        try await testApp(githubAPIClient: client, httpStreamClient: httpClient) { app in
//            try await app.testing().test(.GET, "pointfreeco/swift-overture/0.5.0.zip", headers: ["Accept": "application/vnd.swift.registry.v1+zip"]) { res in
//                #expect(res.status == .ok)
//                let contentType = try #require(res.headers.contentType)
//                #expect(contentType.type == "application" && contentType.subType == "zip")
//                #expect(res.body == contentsByteBuffer)
//            }
//        }
//    }
}

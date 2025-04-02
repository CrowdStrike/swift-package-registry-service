@testable import App
import ConcurrencyExtras
import GithubAPIClient
import ChecksumClient
import HTTPStreamClient
import Testing
import VaporTesting

@Suite("lookupPackageIdentifiers Tests")
struct LookupPackageIdentifiersTests {

    @Test func invalidContentVersionResultsInBadRequest() async throws {
        try await testApp { app in
            // Send version 3 in the Accept header
            try await app.testing().test(.GET, "identifiers?url=https://github.com/pointfreeco/swift-clocks", headers: ["Accept": "application/vnd.swift.registry.v3+json"]) { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func unknownMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send unknown media type
            try await app.testing().test(.GET, "identifiers?url=https://github.com/pointfreeco/swift-clocks", headers: ["Accept": "application/vnd.swift.registry.v1+foobar"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

    @Test func unexpectedSwiftMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send "swift" media type
            try await app.testing().test(.GET, "identifiers?url=https://github.com/pointfreeco/swift-clocks", headers: ["Accept": "application/vnd.swift.registry.v1+swift"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

    @Test func unexpectedZipMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send "zip" media type
            try await app.testing().test(.GET, "identifiers?url=https://github.com/pointfreeco/swift-clocks", headers: ["Accept": "application/vnd.swift.registry.v1+zip"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

    @Test func missingURLQueryParameterResultsInBadRequest() async throws {
        try await testApp { app in
            // Send "zip" media type
            try await app.testing().test(.GET, "identifiers", headers: ["Accept": "application/vnd.swift.registry.v1+json"]) { res in
                #expect(res.status == .badRequest)
            }
        }
    }

//    @Test func githubAPINotFoundResultsInNotFound() async throws {
//        let client: GithubAPIClient = .test(
//            listRepositoryTags: { _ in .other(.init(status: .notFound)) }
//        )
//        try await testApp(githubAPIClient: client) { app in
//            try await app.testing().test(.GET, "identifiers?url=https://github.com/pointfreeco/swift-clocks", headers: ["Accept": "application/vnd.swift.registry.v1+json"]) { res in
//                #expect(res.status == .notFound)
//            }
//        }
//    }
//
//    @Test func githubAPISuccessResultsInSinglePackageIdentifier() async throws {
//        let client: GithubAPIClient = .test(
//            listRepositoryTags: { _ in .mock }
//        )
//        try await testApp(githubAPIClient: client) { app in
//            try await app.testing().test(.GET, "identifiers?url=https://github.com/pointfreeco/swift-clocks", headers: ["Accept": "application/vnd.swift.registry.v1+json"]) { res in
//                #expect(res.status == .ok)
//                let lookupPackageIdentifiers = try res.content.decode(LookupPackageIdentifiers.self)
//                let firstPackageIdentifier = try #require(lookupPackageIdentifiers.identifiers.first)
//                #expect(firstPackageIdentifier == "pointfreeco.swift-clocks")
//            }
//        }
//    }
}

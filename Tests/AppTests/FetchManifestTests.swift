@testable import App
import ConcurrencyExtras
import GithubAPIClient
import ChecksumClient
import HTTPStreamClient
import Testing
import VaporTesting

@Suite("fetchManifest Tests")
struct FetchManifestTests {

    @Test func invalidPackageScopeResultsInBadRequest() async throws {
        try await testApp { app in
            // Use 41 characters in the package scope - 1 character too many
            try await app.testing().test(.GET, "1234567890123456789012345678901234567890/swift-clocks/0.1.0/Package.swift") { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func invalidPackageNameResultsInBadRequest() async throws {
        try await testApp { app in
            // Use two successive hyphens in package name
            try await app.testing().test(.GET, "pointfreeco/swift--clocks/0.1.0/Package.swift") { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func invalidContentVersionResultsInBadRequest() async throws {
        try await testApp { app in
            // Send version 3 in the Accept header
            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.1.0/Package.swift", headers: ["Accept": "application/vnd.swift.registry.v3+swift"]) { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func unknownMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send unknown media type
            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.1.0/Package.swift", headers: ["Accept": "application/vnd.swift.registry.v1+foobar"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

    @Test func unexpectedJsonMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send "json" media type
            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.1.0/Package.swift", headers: ["Accept": "application/vnd.swift.registry.v1+json"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

//    @Test func unversionedManifestRequestResultsInTwoGetContentRequests() async throws {
//        let lockIndex = LockIsolated(0)
//        let client: GithubAPIClient = .test(
//            getContent: { input in
//                defer { lockIndex.withValue { $0 += 1 } }
//                let index = lockIndex.value
//                switch index {
//                case 0:
//                    #expect(input == .mockDirectory)
//                    return .mockDirectoryOneUnversionedManifest
//                case 1:
//                    #expect(input == .mockFile)
//                    return .mockFile
//                default:
//                    // There should only be two requests, no more.
//                    #expect(Bool(false), "We were only expecting 2 GetContent requests, but received more.")
//                    switch input.path {
//                    case .directory:
//                        return .mockDirectoryOneUnversionedManifest
//                    case .file:
//                        return .mockFile
//                    }
//                }
//            }
//        )
//        try await testApp(githubAPIClient: client) { app in
//            try await app.testing().test(.GET, "pointfreeco/swift-overture/0.5.0/Package.swift", headers: ["Accept": "application/vnd.swift.registry.v1+swift"]) { res in
//                #expect(res.status == .ok)
//            }
//        }
//    }
//
//    @Test func versionedManifestRequestResultsInSingleGetContentRequest() async throws {
//        let lockIndex = LockIsolated(0)
//        let client: GithubAPIClient = .test(
//            getContent: { input in
//                defer { lockIndex.withValue { $0 += 1 } }
//                let index = lockIndex.value
//                switch index {
//                case 0:
//                    #expect(input == .mockFileVersioned)
//                    return .mockFile
//                default:
//                    // There should only be one request, no more.
//                    #expect(Bool(false), "We were only expecting 1 GetContent request, but received more.")
//                    switch input.path {
//                    case .directory:
//                        return .mockDirectoryOneUnversionedManifest
//                    case .file:
//                        return .mockFile
//                    }
//                }
//            }
//        )
//        try await testApp(githubAPIClient: client) { app in
//            try await app.testing().test(.GET, "pointfreeco/swift-overture/0.5.0/Package.swift?swift-version=6.0", headers: ["Accept": "application/vnd.swift.registry.v1+swift"]) { res in
//                #expect(res.status == .ok)
//            }
//        }
//    }
//
//    @Test func unversionedManifestGithubNotFoundResultsInNotFound() async throws {
//        let client: GithubAPIClient = .test(
//            getContent: { _ in .notFound }
//        )
//        try await testApp(githubAPIClient: client) { app in
//            try await app.testing().test(.GET, "pointfreeco/swift-overture/0.5.0/Package.swift", headers: ["Accept": "application/vnd.swift.registry.v1+swift"]) { res in
//                #expect(res.status == .notFound)
//            }
//        }
//    }
//
//    @Test func versionedManifestGithubNotFoundResultsInSeeOther() async throws {
//        let client: GithubAPIClient = .test(
//            getContent: { _ in .notFound }
//        )
//        try await testApp(githubAPIClient: client) { app in
//            try await app.testing().test(.GET, "pointfreeco/swift-overture/0.5.0/Package.swift?swift-version=6.0", headers: ["Accept": "application/vnd.swift.registry.v1+swift"]) { res in
//                // If we have a versioned manifest request and there is no manifest with
//                // that version number, then we are supposed to respond with a 303 See Other
//                // and a Location header pointing to the unversioned manifest.
//                #expect(res.status == .seeOther)
//                let locationHeader = try #require(res.headers[.location].first)
//                let urlComponents = try #require(URLComponents(string: locationHeader))
//                #expect(urlComponents.path == "/pointfreeco/swift-overture/0.5.0/Package.swift")
//            }
//        }
//    }
//
//    @Test func noUnversionedManifestFoundResultsInNotFound() async throws {
//        let lockIndex = LockIsolated(0)
//        let client: GithubAPIClient = .test(
//            getContent: { input in
//                defer { lockIndex.withValue { $0 += 1 } }
//                let index = lockIndex.value
//                switch index {
//                case 0:
//                    #expect(input == .mockDirectory)
//                    return .mockDirectoryNoManifest
//                default:
//                    // There should only be one request, no more.
//                    #expect(Bool(false), "We were only expecting 1 GetContent request, but received more.")
//                    switch input.path {
//                    case .directory:
//                        return .mockDirectoryOneUnversionedManifest
//                    case .file:
//                        return .mockFile
//                    }
//                }
//            }
//        )
//        try await testApp(githubAPIClient: client) { app in
//            try await app.testing().test(.GET, "pointfreeco/swift-overture/0.5.0/Package.swift", headers: ["Accept": "application/vnd.swift.registry.v1+swift"]) { res in
//                #expect(res.status == .notFound)
//            }
//        }
//    }
//
//    @Test func multipleVersionedManfiestsProducesLinkHeader() async throws {
//        let lockIndex = LockIsolated(0)
//        let client: GithubAPIClient = .test(
//            getContent: { input in
//                defer { lockIndex.withValue { $0 += 1 } }
//                let index = lockIndex.value
//                switch index {
//                case 0:
//                    #expect(input == .mockDirectory)
//                    return .mockDirectoryMultipleManifests
//                case 1:
//                    #expect(input == .mockFile)
//                    return .mockFile
//                default:
//                    // There should only be two requests, no more.
//                    #expect(Bool(false), "We were only expecting 2 GetContent request, but received more.")
//                    switch input.path {
//                    case .directory:
//                        return .mockDirectoryOneUnversionedManifest
//                    case .file:
//                        return .mockFile
//                    }
//                }
//            }
//        )
//        try await testApp(githubAPIClient: client) { app in
//            try await app.testing().test(.GET, "pointfreeco/swift-overture/0.5.0/Package.swift", headers: ["Accept": "application/vnd.swift.registry.v1+swift"]) { res in
//                #expect(res.status == .ok)
//                let contentType = try #require(res.headers.contentType)
//                #expect(contentType.type == "text" && contentType.subType == "x-swift")
//                let actualLinkHeaders = try #require(res.headers.links)
//                let expectedLinkHeaders: [HTTPHeaders.Link] = [
//                    .init(
//                        uri: "http://127.0.0.1:8080/pointfreeco/swift-overture/0.5.0/Package.swift?swift-version=4.5",
//                        relation: .alternate,
//                        attributes: [
//                            "filename": "Package@swift-4.5.swift"
//                        ]
//                    ),
//                    .init(
//                        uri: "http://127.0.0.1:8080/pointfreeco/swift-overture/0.5.0/Package.swift?swift-version=6.0",
//                        relation: .alternate,
//                        attributes: [
//                            "filename": "Package@swift-6.0.swift"
//                        ]
//                    ),
//                ]
//                #expect(actualLinkHeaders == expectedLinkHeaders)
//            }
//        }
//    }
}

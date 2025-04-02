@testable import App
import ConcurrencyExtras
import GithubAPIClient
import ChecksumClient
import HTTPStreamClient
import HTTPTypes
import Testing
import VaporTesting

@Suite("listPackageReleases Tests")
struct ListPackageReleasesTests {
    @Test func invalidPackageScopeResultsInBadRequest() async throws {
        try await testApp { app in
            // Use 41 characters in the package scope - 1 character too many
            try await app.testing().test(.GET, "1234567890123456789012345678901234567890/swift-clocks") { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func invalidPackageNameResultsInBadRequest() async throws {
        try await testApp { app in
            // Use two successive hyphens in package name
            try await app.testing().test(.GET, "pointfreeco/swift--clocks") { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func invalidContentVersionResultsInBadRequest() async throws {
        try await testApp { app in
            // Send version 3 in the Accept header
            try await app.testing().test(.GET, "pointfreeco/swift-clocks", headers: ["Accept": "application/vnd.swift.registry.v3+json"]) { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func unknownMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send unknown media type
            try await app.testing().test(.GET, "pointfreeco/swift-clocks", headers: ["Accept": "application/vnd.swift.registry.v1+foobar"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

    @Test func unexpectedSwiftMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send "swift" media type
            try await app.testing().test(.GET, "pointfreeco/swift-clocks", headers: ["Accept": "application/vnd.swift.registry.v1+swift"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

    @Test func unexpectedZipMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send "zip" media type
            try await app.testing().test(.GET, "pointfreeco/swift-clocks", headers: ["Accept": "application/vnd.swift.registry.v1+zip"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

//    @Test func canAppendJSONExtension() async throws {
//        let client: GithubAPIClient = .test(
//            repositoryListReleases: { input in
//                #expect(input.owner == "pointfreeco")
//                #expect(input.repo == "swift-clocks")
//                return .mock
//            }
//        )
//        try await testApp(githubAPIClient: client) { app in
//            // Append .json to the package name. Verify that it does not cause failure.
//            try await app.testing().test(.GET, "pointfreeco/swift-clocks.json", headers: ["Accept": "application/vnd.swift.registry.v1+json"]) { res in
//                #expect(res.status == .ok)
//            }
//        }
//    }
//
//    @Test func githubNotFoundResultsInNotFound() async throws {
//        let client: GithubAPIClient = .test(
//            repositoryListReleases: { _ in .notFound }
//        )
//        try await testApp(githubAPIClient: client) { app in
//            // Append .json to the package name. Verify that it does not cause failure.
//            try await app.testing().test(.GET, "pointfreeco/swift-clocks.json", headers: ["Accept": "application/vnd.swift.registry.v1+json"]) { res in
//                #expect(res.status == .notFound)
//            }
//        }
//    }
//
//    @Test func githubTooManyRequestsResultsInTooManyRequests() async throws {
//        let client: GithubAPIClient = .test(
//            repositoryListReleases: { _ in .other(HTTPResponse.Status.tooManyRequests.code) }
//        )
//        try await testApp(githubAPIClient: client) { app in
//            try await app.testing().test(.GET, "pointfreeco/swift-clocks", headers: ["Accept": "application/vnd.swift.registry.v1+json"]) { res in
//                #expect(res.status == .tooManyRequests)
//            }
//        }
//    }
//
//    @Test func linkHeadersArePassedOnIfClientSupportsPagination() async throws {
//        let githubAPILinkHeaders: [HTTPHeaders.Link] = [
//            .init(uri: "https://api.github.com/repositories/143079594/tags?per_page=100&page=2", relation: .next, attributes: [:]),
//            .init(uri: "https://api.github.com/repositories/143079594/tags?per_page=100&page=15", relation: .last, attributes: [:]),
//        ]
//        let expectedOutputLinkHeaders: [HTTPHeaders.Link] = [
//            .init(uri: "http://127.0.0.1:8080/pointfreeco/swift-clocks?per_page=100&page=2", relation: .next, attributes: [:]),
//            .init(uri: "http://127.0.0.1:8080/pointfreeco/swift-clocks?per_page=100&page=15", relation: .last, attributes: [:]),
//        ]
//        let client: GithubAPIClient = .test(
//            repositoryListReleases: { _ in .ok(.init(linkHeader: githubAPILinkHeaders.renderedText, releases: [])) }
//        )
//        try await testApp(githubAPIClient: client, clientSupportsPagination: true) { app in
//            try await app.testing().test(.GET, "pointfreeco/swift-clocks", headers: ["Accept": "application/vnd.swift.registry.v1+json"]) { res in
//                #expect(res.status == .ok)
//                #expect(res.headers.links == expectedOutputLinkHeaders)
//            }
//        }
//    }
//
//    @Test func multipleGithubAPIFetchesIfClientDoesNotSupportPagination() async throws {
//        let githubAPIResponses: [GithubAPIClient.RepositoryListReleases.Output] = [
//            .ok(
//                .init(
//                    linkHeader: [
//                        HTTPHeaders.Link(
//                            uri: "https://api.github.com/repositories/143079594/tags?per_page=10&page=2",
//                            relation: .next,
//                            attributes: [:]
//                        ),
//                        HTTPHeaders.Link(
//                            uri: "https://api.github.com/repositories/143079594/tags?per_page=10&page=3",
//                            relation: .last,
//                            attributes: [:]
//                        ),
//                    ].renderedText,
//                    releases: [
//                        .init(id: 0, tagName: "0.1.0"),
//                        .init(id: 1, tagName: "0.1.1"),
//                        .init(id: 2, tagName: "0.1.2"),
//                        .init(id: 3, tagName: "0.1.3"),
//                        .init(id: 4, tagName: "0.1.4"),
//                        .init(id: 5, tagName: "0.1.5"),
//                        .init(id: 6, tagName: "0.1.6"),
//                        .init(id: 7, tagName: "0.1.7"),
//                        .init(id: 8, tagName: "0.1.8"),
//                        .init(id: 9, tagName: "0.1.9"),
//                    ]
//                )
//            ),
//            .ok(
//                .init(
//                    linkHeader: [
//                        HTTPHeaders.Link(
//                            uri: "https://api.github.com/repositories/143079594/tags?per_page=10&page=3",
//                            relation: .next,
//                            attributes: [:]
//                        ),
//                        HTTPHeaders.Link(
//                            uri: "https://api.github.com/repositories/143079594/tags?per_page=10&page=3",
//                            relation: .last,
//                            attributes: [:]
//                        ),
//                    ].renderedText,
//                    releases: [
//                        .init(id: 10, tagName: "0.2.0"),
//                        .init(id: 11, tagName: "0.2.1"),
//                        .init(id: 12, tagName: "0.2.2"),
//                        .init(id: 13, tagName: "0.2.3"),
//                        .init(id: 14, tagName: "0.2.4"),
//                        .init(id: 15, tagName: "0.2.5"),
//                        .init(id: 16, tagName: "0.2.6"),
//                        .init(id: 17, tagName: "0.2.7"),
//                        .init(id: 18, tagName: "0.2.8"),
//                        .init(id: 19, tagName: "0.2.9"),
//                    ]
//                )
//            ),
//            .ok(
//                .init(
//                    linkHeader: [
//                        HTTPHeaders.Link(
//                            uri: "https://api.github.com/repositories/143079594/tags?per_page=10&page=1",
//                            relation: .first,
//                            attributes: [:]
//                        ),
//                        HTTPHeaders.Link(
//                            uri: "https://api.github.com/repositories/143079594/tags?per_page=10&page=2",
//                            relation: .prev,
//                            attributes: [:]
//                        ),
//                    ].renderedText,
//                    releases: [
//                        .init(id: 20, tagName: "0.3.0"),
//                        .init(id: 21, tagName: "0.3.1"),
//                        .init(id: 22, tagName: "0.3.2"),
//                        .init(id: 23, tagName: "0.3.3"),
//                        .init(id: 24, tagName: "0.3.4"),
//                        .init(id: 25, tagName: "0.3.5"),
//                        .init(id: 26, tagName: "0.3.6"),
//                        .init(id: 27, tagName: "0.3.7"),
//                        .init(id: 28, tagName: "0.3.8"),
//                        .init(id: 29, tagName: "0.3.9"),
//                    ]
//                )
//            ),
//        ]
//        let lockIndex = LockIsolated(0)
//        let client: GithubAPIClient = .test(
//            repositoryListReleases: { _ in
//                defer {
//                    lockIndex.withValue { $0 += 1 }
//                }
//                let index = lockIndex.value
//                if index < githubAPIResponses.count {
//                    return githubAPIResponses[index]
//                } else {
//                    return .other(HTTPResponse.Status.internalServerError.code)
//                }
//            }
//        )
//        try await testApp(githubAPIClient: client, clientSupportsPagination: false) { app in
//            try await app.testing().test(.GET, "pointfreeco/swift-clocks", headers: ["Accept": "application/vnd.swift.registry.v1+json"]) { res in
//                #expect(res.status == .ok)
//                #expect(res.headers.links.isNilOrEmpty)
//                let listPackageReleasesResponse = try res.content.decode(ListPackageReleases.self)
//                #expect(listPackageReleasesResponse.releases.keys.count == 30)
//                // Three requests should have been done
//                #expect(lockIndex.value == 3)
//            }
//        }
//    }
}

extension HTTPHeaders.Link: @unchecked Sendable { }

extension HTTPHeaders.Link: Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.uri == rhs.uri && lhs.relation == rhs.relation && lhs.attributes == rhs.attributes
    }
}

extension Optional where Wrapped == [HTTPHeaders.Link] {
    var isNilOrEmpty: Bool {
        switch self {
        case .none: return true
        case .some(let links): return links.isEmpty
        }
    }
}

extension HTTPHeaders.Link {
    var renderedText: String {
        ["<\(uri)>", "rel=\"\(relation.rawValue)\""].joined(separator: "; ")
    }
}

extension Array where Element == HTTPHeaders.Link {
    var renderedText: String {
        map(\.renderedText).joined(separator: ", ")
    }
}

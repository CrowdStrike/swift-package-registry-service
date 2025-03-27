import APIUtilities
import Vapor

struct ListPackageReleases: Content {
    var linkHeader: String?
    var releases: [String: Release]

    init(releases: [String: Release]) {
        self.releases = releases
    }

    init(linkHeader: String? = nil, versions: [Version] = []) {
        self.linkHeader = linkHeader
        self.releases = versions.reduce(into: [String: Release]()) { $0[$1.description] = .init() }
    }

    mutating func fixupURLs(serverURL: String, scope: String, name: String) {
        releases.keys.forEach { tag in
            releases[tag] = .init(url: "\(serverURL)/\(scope)/\(name)/\(tag)")
        }
    }

    struct Release: Content {
        var url: String?
        var problem: ProblemDetails?

        init(url: String? = nil, problem: ProblemDetails? = nil) {
            self.url = url
            self.problem = problem
        }
    }

    enum CodingKeys: String, CodingKey {
        case releases
    }
}

extension ListPackageReleases: AsyncResponseEncodable {

    func encodeResponse(for request: Request) async throws -> Response {
        let scopeAndName = try request.packageScopeAndName
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/json")
        headers.add(name: .contentVersion, value: SwiftRegistryAcceptHeader.Version.v1.rawValue)
        if let linkHeader = APIUtilities.listPackageReleasesLinkHeader(
            from: linkHeader,
            serverURLString: request.serverURL,
            owner: scopeAndName.scope.value,
            repo: scopeAndName.name.value
        ) {
            headers.add(name: .link, value: linkHeader)
        }
        var mutableCopy = self
        mutableCopy.fixupURLs(serverURL: request.serverURL, scope: scopeAndName.scope.value, name: scopeAndName.name.value)
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .default
        let data = try jsonEncoder.encode(mutableCopy)
        return .init(status: .ok, headers: headers, body: .init(data: data))
    }
}

extension ListPackageReleases {
    static let mock = Self(
        releases: [
            "0.5.0": .init(url: "http://127.0.0.1:8080/pointfreeco/swift-overture/0.5.0"),
            "0.4.0": .init(url: "http://127.0.0.1:8080/pointfreeco/swift-overture/0.4.0"),
            "0.3.1": .init(url: "http://127.0.0.1:8080/pointfreeco/swift-overture/0.3.1"),
            "0.3.0": .init(url: "http://127.0.0.1:8080/pointfreeco/swift-overture/0.3.0"),
            "0.2.0": .init(url: "http://127.0.0.1:8080/pointfreeco/swift-overture/0.2.0"),
            "0.1.0": .init(url: "http://127.0.0.1:8080/pointfreeco/swift-overture/0.1.0"),
        ]
    )
}

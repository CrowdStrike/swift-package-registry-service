import APIUtilities
import GithubAPIClient
import NIOHTTP1
import PersistenceClient
import Vapor

extension PackageRegistryController {

    func fetchManifest(req: Request) async throws -> FetchedManifest {
        let packageScope = try req.packageScope
        let packageName = try req.packageName
        let packageVersion = try req.packageVersion
        let queryParams = try req.query.decode(FetchManifestQueryParameters.self)
        try req.checkAcceptHeader(expectedMediaType: .swift)

        // Make sure the version is a valid semantic version.
        let version = try packageVersion.semanticVersion

        let owner = packageScope.value
        let repo = packageName.value

        // Sync the package manifests against the cache
        let manifests = try await manifestsActor.loadManifests(owner: owner, repo: repo, version: version)

        if let swiftVersion = queryParams.swiftVersion {
            // We have a swift-version query parameter. Check if we have a manifest with this version
            guard let manifestForOurVersion = manifests.first(where: { $0.swiftVersion == swiftVersion }) else {
                // The caller requested a manifest with a swift-version which does not exist
                // in the repo. So per the spec, we return a 303 See Other with a Location
                // header pointing to the main Package.swift
                return .init(response: .seeOther)
            }
            guard let contents = manifestForOurVersion.contents, contents.readableBytes > 0 else {
                throw Abort(.internalServerError, title: "Cached manifest is empty.")
            }
            return .init(
                response: .ok(
                    .init(
                        allManifestFiles: [],
                        fileName: manifestForOurVersion.fileName,
                        value: .init(buffer: contents)
                    )
                )
            )
        } else {
            // We don't have a ?swift-version query parameter, so this
            // is a request for the base Package.swift.
            guard
                let unversionedManifest = manifests.first(where: \.isUnversioned),
                let unversionedManifestContents = unversionedManifest.contents,
                unversionedManifestContents.readableBytes > 0
            else {
                throw Abort(.notFound, title: "Package.swift not found in repository.")
            }
            let versionedManifests = manifests.filter(\.hasVersion)
            
            return .init(
                response: .ok(
                    .init(
                        allManifestFiles: versionedManifests.map(\.asManifestFile),
                        fileName: unversionedManifest.fileName,
                        value: .init(buffer: unversionedManifestContents)
                    )
                )
            )
        }
    }

    private struct FetchManifestQueryParameters: Content {
        var swiftVersion: String?

        enum CodingKeys: String, CodingKey {
            case swiftVersion = "swift-version"
        }

        var fileName: String {
            var name = "Package"
            if let swiftVersion {
                name += "@swift-\(swiftVersion)"
            }
            name += ".swift"
            return name
        }
    }
}

extension GithubAPIClient.GetContent.Output {

    func toFetchedManifest(allManifestFiles: [Manifest.File] = []) throws -> FetchedManifest {
        switch self {
        case .ok(let okBody):
            let file = try okBody.file
            return .init(
                response: .ok(
                    .init(
                        allManifestFiles: allManifestFiles,
                        fileName: file.name,
                        value: try file.decodedContent
                    )
                )
            )
        case .notFound:
            return .init(response: .seeOther)
        default:
            throw Abort(httpResponseStatus)
        }
    }

    var okBody: GithubAPIClient.GetContent.OKBody {
        get throws {
            switch self {
            case .ok(let okBody):
                return okBody
            default:
                throw Abort(httpResponseStatus)
            }
        }
    }

    var httpResponseStatus: HTTPResponseStatus {
        switch self {
        case .ok: .ok
        case .found: .found
        case .notModified: .notModified
        case .forbidden: .forbidden
        case .notFound: .notFound
        case .other(let httpResponse): .init(statusCode: httpResponse.status.code)
        }
    }
}

extension GithubAPIClient.GetContent.OKBody {

    var file: File {
        get throws {
            switch self {
            case .file(let fileStruct):
                return fileStruct
            default:
                throw Abort(.internalServerError, title: "Unexpected content returned from Github API.")
            }
        }
    }
}

extension GithubAPIClient.GetContent.OKBody.File {

    var decodedContent: String {
        get throws {
            guard encoding == "base64" else {
                throw Abort(.internalServerError, title: "Unexpected encoding returned from Github API.")
            }
            let contentMinusLinefeeds = content.replacingOccurrences(of: "\n", with: "")
            guard
                let decodedData = Data(base64Encoded: contentMinusLinefeeds),
                let decodedString = String(data: decodedData, encoding: .utf8)
            else {
                throw Abort(.internalServerError, title: "Could not Base64-decode content returned from Github API.")
            }
            return decodedString
        }
    }
}

extension PersistenceClient.Manifest {

    var asManifestFile: Manifest.File {
        .init(
            fileName: asManifestFileName,
            swiftToolsVersion: swiftToolsVersion
        )
    }

    var asManifestFileName: Manifest.FileName {
        switch swiftVersion {
        case .none:
            .unversioned
        case .some(let version):
            .versioned(version)
        }
    }
}

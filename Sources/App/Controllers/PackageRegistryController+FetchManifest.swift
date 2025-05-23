import APIUtilities
import GithubAPIClient
import NIOHTTP1
import PersistenceClient
import Vapor

extension PackageRegistryController {

    func fetchManifest(req: Request) async throws -> Response {
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
        let manifests = try await manifestsActor.loadData(
            owner: owner,
            repo: repo,
            version: version,
            req: req
        )

        let swiftMediaType = HTTPMediaType(type: "text", subType: "x-swift")
        let logger = req.logger

        if let swiftVersion = queryParams.swiftVersion {
            // We have a swift-version query parameter. Check if we have a manifest with this version
            guard let manifestForOurVersion = manifests.first(where: { $0.packageManifest.swiftVersion == swiftVersion }) else {
                // The caller requested a manifest with a swift-version which does not exist
                // in the repo. So per the spec, we return a 303 See Other with a Location
                // header pointing to the main Package.swift
                var headers = HTTPHeaders()
                headers.add(name: .location, value: try req.unversionedManifestURL)
                return .init(status: .seeOther, headers: headers)
            }
            // Make sure we have a cachedFilePath for this manifest
            guard !manifestForOurVersion.cacheFileName.isEmpty else {
                throw Abort(.internalServerError, title: "No cached manifest file.")
            }
            // Get the full path to the manifest file
            let cachedFilePath = Self.manifestFilePath(
                cacheRootDirectory: cacheRootDirectory,
                manifestFileName: manifestForOurVersion.cacheFileName
            )

            let response = try await req.fileio.asyncStreamFile(
                at: cachedFilePath,
                mediaType: swiftMediaType
            ) { result in
                switch result {
                case .success:
                    logger.debug("Successfully streamed manifest file to response.")
                case .failure(let error):
                    logger.error("Error streaming manifest file to response: \(error)")
                }
            }
            response.headers.add(
                name: .contentVersion,
                value: SwiftRegistryAcceptHeader.Version.v1.rawValue
            )
            response.headers.add(
                name: .contentDisposition,
                value: "attachment; filename=\"\(manifestForOurVersion.packageManifest.fileName)\""
            )

            return response
        } else {
            // We don't have a ?swift-version query parameter, so this
            // is a request for the base Package.swift.
            guard let unversionedManifest = manifests.first(where: \.packageManifest.isUnversioned) else {
                throw Abort(.notFound, title: "Package.swift not found in repository.")
            }
            // Make sure we have a cachedFilePath for this manifest
            guard !unversionedManifest.cacheFileName.isEmpty else {
                throw Abort(.internalServerError, title: "No cached manifest file for Package.swift.")
            }
            // Get the full path to the manifest file
            let cachedFilePath = Self.manifestFilePath(
                cacheRootDirectory: cacheRootDirectory,
                manifestFileName: unversionedManifest.cacheFileName
            )

            let response = try await req.fileio.asyncStreamFile(
                at: cachedFilePath,
                mediaType: swiftMediaType
            ) { result in
                switch result {
                case .success:
                    logger.debug("Successfully streamed manifest file to response.")
                case .failure(let error):
                    logger.error("Error streaming manifest file to response: \(error)")
                }
            }
            response.headers.add(
                name: .contentVersion,
                value: SwiftRegistryAcceptHeader.Version.v1.rawValue
            )
            response.headers.add(
                name: .contentDisposition,
                value: "attachment; filename=\"\(unversionedManifest.packageManifest.fileName)\""
            )

            // If we have versioned manifests in the same repository,
            // then we need to generate a Link header.
            let versionedManifests = manifests.filter(\.packageManifest.hasVersion)
            if !versionedManifests.isEmpty {
                let linkHeader = try versionedManifests
                    .map { try $0.linkHeaderValue(for: req) }
                    .joined(separator: ", ")
                response.headers.add(name: .link, value: linkHeader)
            }

            return response
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

extension CachedPackageManifest {

    var asManifestFile: APIUtilities.Manifest.File {
        .init(
            fileName: asManifestFileName,
            swiftToolsVersion: packageManifest.swiftToolsVersion
        )
    }

    var asManifestFileName: APIUtilities.Manifest.FileName {
        switch packageManifest.swiftVersion {
        case .none:
            .unversioned
        case .some(let version):
            .versioned(version)
        }
    }

    var queryArguments: String {
        switch packageManifest.swiftVersion {
        case .none: ""
        case .some(let swiftVersion): "?swift-version=\(swiftVersion)"
        }
    }


    func linkHeaderValue(for request: Request) throws -> String {
        var components = [String]()
        components.append("<\(try request.fetchPackageMetadataURL)/Package.swift\(queryArguments)>")
        components.append("rel=\"alternate\"")
        components.append("filename=\"\(packageManifest.fileName)\"")
        components.append("swift-tools-version=\"\(packageManifest.swiftToolsVersion)\"")
        return components.joined(separator: "; ")
    }
}

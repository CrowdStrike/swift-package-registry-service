import APIUtilities
import AsyncHTTPClient
import GithubAPIClient
import HTTPStreamClient
import System
import Vapor

extension PackageRegistryController {

    func downloadSourceArchive(req: Request) async throws -> Response {
        req.logger.debug("downloadSourceArchive(req: \(req))")
        let packageScopeAndName = try req.packageScopeAndName
        let packageVersion = try req.packageVersion
        try req.checkAcceptHeader(expectedMediaType: .zip)

        // Make sure the version is a valid semantic version.
        let version = try packageVersion.semanticVersion

        let owner = packageScopeAndName.scope.value
        let repo = packageScopeAndName.name.value

        // Sync the release metadata. This sync fetches the source archive (zipBall)
        // from Github, caches it, and computes the checksum on it.
        let releaseMetadata = try await releaseMetadataActor.loadData(
            owner: owner,
            repo: repo,
            version: version,
            req: req
        )

        // Get the cached file path to the source archive
        let cachedSourceArchiveFilePath = Self.cachedSourceArchiveFilePath(
            cacheRootDirectory: cacheRootDirectory,
            sourceArchiveFileName: releaseMetadata.cacheFileName
        )

        let response = try await req.fileio.asyncStreamFile(at: cachedSourceArchiveFilePath) { result in
            switch result {
            case .success:
                req.logger.debug("Successfully streamed source archive file to response.")
            case .failure(let error):
                req.logger.error("Error streaming source archive file to response: \(error)")
            }
        }

        let fileName = "\(owner)_\(repo)_\(version.description).zip"
        response.headers.add(name: .contentDisposition, value: "attachment; filename=\"\(fileName)\"")
        response.headers.add(name: .contentVersion, value: SwiftRegistryAcceptHeader.Version.v1.rawValue)

        return response
    }
}

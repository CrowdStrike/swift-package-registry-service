import AsyncHTTPClient
import GithubAPIClient
import HTTPStreamClient
import Vapor

extension PackageRegistryController {

    func downloadSourceArchive(req: Request) async throws -> SourceArchive {
        let logger = Logger(label: "downloadSourceArchive")
        logger.debug("downloadSourceArchive(req: \(req))")
        let packageScopeAndName = try req.packageScopeAndName
        let packageVersion = try req.packageVersion
        try req.checkAcceptHeader(expectedMediaType: .zip)

        // Make sure the version is a valid semantic version.
        let version = try packageVersion.semanticVersion

        let owner = packageScopeAndName.scope.value
        let repo = packageScopeAndName.name.value

        // Sync the release metadata. This sync fetches the source archive (zipBall)
        // from Github, caches it, and computes the checksum on it.
        _ = try await releaseMetadataActor.loadData(owner: owner, repo: repo, version: version, logger: req.logger)

        // Once we sync the release metadata, then the source
        // archive should be cached. If it's not, that's an error.
        guard let cachedSourceArchive = try await persistenceClient.readSourceArchive(owner: owner, repo: repo, version: version) else {
            logger.error("Could not find expected cached source archive for \"\(owner).\(repo)\" version \(version).")
            throw Abort(.internalServerError, title: "Could not load source archive from cache.")
        }

        logger.debug("Found cached source archive for \"\(owner).\(repo)\" version \(version).")

        return .init(
            contentDispositionHeaderValue: "attachment; filename=\"\(cachedSourceArchive.fileName)\"",
            value: cachedSourceArchive.byteBuffer
        )
    }
}

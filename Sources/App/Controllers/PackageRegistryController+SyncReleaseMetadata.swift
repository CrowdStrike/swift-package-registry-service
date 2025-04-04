import APIUtilities
import ChecksumClient
import GithubAPIClient
import PersistenceClient
import Vapor

extension PackageRegistryController {

    static func syncReleaseMetadata(
        owner: String,
        repo: String,
        version: Version,
        githubAPIClient: GithubAPIClient,
        persistenceClient: PersistenceClient,
        checksumClient: ChecksumClient,
        logger: Logger,
        tagsActor: TagsActor
    ) async throws -> PersistenceClient.ReleaseMetadata {
        if let cachedReleaseMetadata = try await persistenceClient.readReleaseMetadata(owner: owner, repo: repo, version: version) {
            logger.debug("Found cached release metadata for \"\(owner).\(repo)\" version: \(version)")
            return cachedReleaseMetadata
        } else {
            logger.debug("Did not find cached release metadata for \"\(owner).\(repo)\" version: \(version)")
        }

        // Get the cached tag information. Since the fetchReleaseMetadata call
        // almost always comes after the listPackageReleases call in SPM, then
        // we assume that we already did a tag sync when the listPackageReleases
        // was called. So we don't force a sync now.
        let tagFile = try await tagsActor.loadTagFile(owner: owner, repo: repo, forceSync: false, logger: logger)

        // Look up a tag with the requested semantic version
        guard
            let tagName = tagFile.versionToTagName[version],
            let tag = tagFile.tags.first(where: { $0.name == tagName })
        else {
            logger.error("Could not find tag with semantic version \"\(version)\" for \"\(owner).\(repo)\".")
            throw Abort(.internalServerError, title: "Could not find tag with semantic version \"\(version)\".")
        }

        // The Github /repos/{owner}/{repo}/tags endpoint provides tags information,
        // but the tag information does not contain createdAt or publishedAt information.
        // However, for *most* repositories, there is also a "release" associated with
        // this tag, and release information *does* contain createdAt and publishedAt.
        // So here we attempt to fetch the release by the tag name. If we find it,
        // then pull out the publishedAt date to provide in the release metadata.
        // However, it is not an error if the "fetch release by tag name" fails - this
        // may be a tag with no corresponding release.
        let publishedAt = try await githubAPIClient.getReleaseByTagName(.init(owner: owner, repo: repo, tag: tagName)).publishedAt

        // Cache the zipBall
        let zipBallPath = try await persistenceClient.saveSourceArchive(owner: owner, repo: repo, version: version, zipBallURL: tag.zipBallURL)
        logger.debug("Downloaded \"\(tag.zipBallURL)\" to \"\(zipBallPath)\"")

        // Compute the checksum from the cached zipBall file
        let checksum = try await checksumClient.computeFileChecksum(path: zipBallPath)
        logger.debug("Computed checksum of \"\(zipBallPath)\" as \(checksum)")

        // Construct the ReleaseMetadata
        let releaseMetadata = PersistenceClient.ReleaseMetadata(checksum: checksum, tag: tag, version: version, publishedAt: publishedAt)

        // Cache the ReleaseMetadata
        try await persistenceClient.saveReleaseMetadata(owner: owner, repo: repo, metadata: releaseMetadata)
        logger.debug("Cached release metadata for \"\(owner).\(repo)\" version: \(version).")

        return releaseMetadata
    }
}

extension GithubAPIClient.GetReleaseByTagName.Output {

    var release: GithubAPIClient.Release {
        get throws {
            switch self {
            case .ok(let release):
                return release
            case .notFound:
                throw Abort(.notFound)
            case .other(let httpResponse):
                throw Abort(.init(statusCode: httpResponse.status.code))
            }
        }
    }

    /// Get the `publishedAt` Date.
    /// This accessor does not throw an error if we get a Not Found or other HTTP error.
    /// Instead, it just returns a `nil`.
    var publishedAt: Date? {
        switch self {
        case .ok(let release):
            return release.publishedAt
        default:
            return nil
        }
    }
}

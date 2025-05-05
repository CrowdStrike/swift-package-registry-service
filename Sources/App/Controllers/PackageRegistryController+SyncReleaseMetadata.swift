import APIUtilities
import AsyncHTTPClient
import ChecksumClient
import Dependencies
import Fluent
import GithubAPIClient
import Vapor

extension PackageRegistryController {

    static func syncReleaseMetadata(
        owner: String,
        repo: String,
        version: Version,
        githubAPIClient: GithubAPIClient,
        checksumClient: ChecksumClient,
        tagsActor: TagsActor,
        databaseActor: DatabaseActor,
        cacheRootDirectory: String,
        uuidGenerator: UUIDGenerator,
        req: Request
    ) async throws -> PackageReleaseMetadata {
        let packageRelease = try await PackageRelease.query(on: req.db)
            .filter(\.$packageScope == owner)
            .filter(\.$packageName == repo)
            .filter(\.$packageVersion == version.description)
            .first()
        let releaseId = "\"\(owner).\(repo)\" \(version.description)"
        if let packageRelease {
            req.logger.debug("Found cached PackageRelease for \(releaseId)")
            return packageRelease.asPackageReleaseMetadata
        } else {
            req.logger.debug("Did not find cached PackageRelease for \(releaseId)")
        }

        // Get the cached tag information. Since the fetchReleaseMetadata call
        // almost always comes after the listPackageReleases call in SPM, then
        // we assume that we already did a tag sync when the listPackageReleases
        // was called. So we don't force a sync now.
        let tagFile = try await tagsActor.loadTagFile(
            owner: owner,
            repo: repo,
            forceSync: false,
            logger: req.logger
        )

        // Look up a tag with the requested semantic version
        guard
            let tagName = tagFile.versionToTagName[version],
            let tag = tagFile.tags.first(where: { $0.name == tagName })
        else {
            req.logger.error("Could not find tag with semantic version \"\(version)\" for \"\(owner).\(repo)\".")
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
        let input = GithubAPIClient.GetReleaseByTagName.Input(owner: owner, repo: repo, tag: tagName)
        let publishedAt = try await githubAPIClient.getReleaseByTagName(input).publishedAt

        // Cache the zipBall
        let sourceArchiveFileName = "\(uuidGenerator().uuidString).zip"
        let cachedSourceArchivePath = Self.cachedSourceArchiveFilePath(
            cacheRootDirectory: cacheRootDirectory,
            sourceArchiveFileName: sourceArchiveFileName
        )
        try await downloadSourceArchive(
            url: tag.zipBallURL,
            to: cachedSourceArchivePath,
            httpClient: req.application.http.client.shared,
            logger: req.logger
        )
        req.logger.debug("Downloaded \"\(tag.zipBallURL)\" to \"\(cachedSourceArchivePath)\"")

        // Compute the checksum from the cached source archive .zip file
        let checksum = try await checksumClient.computeFileChecksum(path: cachedSourceArchivePath)
        req.logger.debug("Computed checksum of \"\(cachedSourceArchivePath)\" as \(checksum)")

        // Construct the PackageReleaseMetadata
        let packageReleaseMetadata = PackageReleaseMetadata(
            packageScope: owner,
            packageName: repo,
            packageVersion: version.description,
            tagName: tag.name,
            publishedAt: publishedAt,
            zipBallURL: tag.zipBallURL,
            cacheFileName: sourceArchiveFileName,
            checksum: checksum
        )

        // Write the PackageReleaseMetadata to the DB
        try await databaseActor.addPackageRelease(packageReleaseMetadata, logger: req.logger, database: req.db)
        req.logger.debug("Cached release metadata for \"\(owner).\(repo)\" version: \(version).")

        return packageReleaseMetadata
    }

    private static func downloadSourceArchive(
        url: String,
        to path: String,
        httpClient: HTTPClient,
        logger: Logger
    ) async throws {
        let request = try HTTPClient.Request(url: url)

        let delegate = try FileDownloadDelegate(path: path, reportProgress: { progress in
            if let totalBytes = progress.totalBytes {
                logger.debug("Downloading: \(progress.receivedBytes) bytes of \(totalBytes)")
            } else {
                logger.debug("Downloading: \(progress.receivedBytes) bytes")
            }
        })

        let progress = try await httpClient.execute(request: request, delegate: delegate, logger: logger).get()

        if let totalBytes = progress.totalBytes {
            logger.debug("Downloaded: \(progress.receivedBytes) bytes of \(totalBytes)")
        } else {
            logger.debug("Downloaded: \(progress.receivedBytes) bytes")
        }
    }

    static func cachedSourceArchiveFilePath(
        cacheRootDirectory: String,
        sourceArchiveFileName: String
    ) -> String {
        "\(cacheRootDirectory)/sourceArchives/\(sourceArchiveFileName)"
    }
}

private extension PackageRelease {
    var asPackageReleaseMetadata: PackageReleaseMetadata {
        .init(
            packageScope: packageScope,
            packageName: packageName,
            packageVersion: packageVersion,
            tagName: tagName,
            publishedAt: publishedAt,
            zipBallURL: zipBallURL,
            cacheFileName: cacheFileName,
            checksum: checksum
        )
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

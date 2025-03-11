import APIUtilities
import ChecksumClient
import GithubAPIClient
import PersistenceClient
import Vapor

extension PackageRegistryController {
    func syncManifests(owner: String, repo: String, version: Version) async throws -> [PersistenceClient.Manifest] {
        // Attempt to read in all of the package manifests from cache
        let manifests = try await persistenceClient.readManifests(owner: owner, repo: repo, version: version)
        guard manifests.isEmpty else {
            logger.debug("Found \(manifests.count) cached manifests for \"\(owner).\(repo)\" version: \(version)")
            return manifests
        }
        logger.debug("Did not find any cached manifests for \"\(owner).\(repo)\" version: \(version)")

        // Get the cached tag information. Since the fetchManifest call
        // almost always comes after the listPackageReleases call in SPM, then
        // we assume that we already did a tag sync when the listPackageReleases
        // was called. So we don't force a sync now.
        let tagFile = try await syncTags(owner: owner, repo: repo, forceSync: false)

        // Look up the tag name for the requested semantic version
        guard let tagName = tagFile.versionToTagName[version] else {
            logger.error("Could not find tag with semantic version \"\(version)\" for \"\(owner).\(repo)\".")
            throw Abort(.internalServerError, title: "Could not find tag with semantic version \"\(version)\".")
        }

        // First we fetch the contents of the root repo directory.
        // Note that we are the tag name here for the ref, and NOT the version,
        // since they could be different. (The tag name could be "v4.4.0", while the
        // semantic version would be "4.4.0".)
        let dirInput = GithubAPIClient.GetContent.Input(owner: owner, repo: repo, path: .directory, ref: tagName)
        let dirOutput = try await githubAPIClient.getContent(dirInput)
        // Get the filenames of all the versioned and unversioned
        // package manifests in the directory.
        let manifestFileNames = try Manifest.fileNames(from: dirOutput.directoryFileNames)
        // If we don't have any manifests, then fail out
        guard !manifestFileNames.isEmpty else {
            throw Abort(.notFound, title: "No manifest files found.")
        }
        logger.debug("Fetched repo root directory - found \(manifestFileNames.count) manifests for \"\(owner).\(repo)\" version: \(version)")
        // Fetch all the manifests in parallel
        let fetchedManifests = try await withThrowingTaskGroup(of: PersistenceClient.Manifest.self, returning: [PersistenceClient.Manifest].self) { group in
            manifestFileNames.forEach { manifestFileName in
                group.addTask {
                    try await Self.fetchManifest(
                        owner: owner,
                        repo: repo,
                        version: version,
                        tagName: tagName,
                        manifestFileName: manifestFileName,
                        githubAPIClient: githubAPIClient,
                        logger: logger
                    )
                }
            }
            var manifests = [PersistenceClient.Manifest]()
            for try await manifest in group {
                manifests.append(manifest)
            }
            return manifests
        }
        logger.debug("Fetched \(fetchedManifests.count) manifests for \"\(owner).\(repo)\" version: \(version)")
        // Persist these manifests
        try await persistenceClient.saveManifests(owner: owner, repo: repo, version: version, manifests: fetchedManifests)
        logger.debug("Saved \(fetchedManifests.count) manifests to cache for \"\(owner).\(repo)\" version: \(version)")

        return fetchedManifests
    }

    private static func fetchManifest(
        owner: String,
        repo: String,
        version: Version,
        tagName: String,
        manifestFileName: Manifest.FileName,
        githubAPIClient: GithubAPIClient,
        logger: Logger
    ) async throws -> PersistenceClient.Manifest {
        logger.debug("Fetching \"\(manifestFileName.fileName)\" for \"\(owner).\(repo)\" version: \(version)")
        let clientInput = GithubAPIClient.GetContent.Input(owner: owner, repo: repo, path: .file(manifestFileName.fileName), ref: tagName)
        let clientOutput = try await githubAPIClient.getContent(clientInput)
        let file = try clientOutput.okBody.file
        let fileContents = try file.decodedContent
        let swiftToolsVersion = try SwiftToolsVersionParser().parse(fileContents)
        logger.debug("Fetched \"\(manifestFileName.fileName)\" for \"\(owner).\(repo)\" version: \(version) swiftToolsVersion: \(String(describing: swiftToolsVersion))")
        return .init(
            fileName: manifestFileName.fileName,
            swiftVersion: manifestFileName.swiftVersion,
            swiftToolsVersion: swiftToolsVersion,
            contents: ByteBuffer(string: fileContents)
        )
    }
}

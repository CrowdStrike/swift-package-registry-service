import APIUtilities
import ChecksumClient
import PersistenceClient
import GithubAPIClient
import Vapor

extension PackageRegistryController {

    func fetchReleaseMetadata(req: Request) async throws -> FetchReleaseMetadata {
        let packageScopeAndName = try req.packageScopeAndName
        let packageVersion = try req.packageVersion
        try req.checkAcceptHeader(expectedMediaType: .json)

        // Make sure the version is a valid semantic version.
        let version = try packageVersion.semanticVersion

        let owner = packageScopeAndName.scope.value
        let repo = packageScopeAndName.name.value

        // Sync the release metadata
        let releaseMetadata = try await releaseMetadataActor.loadReleaseMetadata(owner: owner, repo: repo, version: version, logger: req.logger)

        // Return the FetchReleaseMetadata
        return .init(
            id: packageScopeAndName.packageId,
            version: version.description,
            resources: [
                .sourceArchive(withChecksum: releaseMetadata.checksum)
            ],
            metadata: .metadata(scope: owner, name: repo),
            publishedAt: releaseMetadata.publishedAt
        )
    }
}

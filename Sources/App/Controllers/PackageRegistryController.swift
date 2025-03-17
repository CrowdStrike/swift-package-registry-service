import Dependencies
import ChecksumClient
import Foundation
import GithubAPIClient
import HTTPStreamClient
import PersistenceClient
import Vapor

struct PackageRegistryController: RouteCollection {
    typealias GetDateNow = @Sendable () -> Date

    let serverURLString: String
    let clientSupportsPagination: Bool
    let githubAPIToken: String
    let githubAPIClient: GithubAPIClient
    let checksumClient: ChecksumClient
    let httpStreamClient: HTTPStreamClient
    let persistenceClient: PersistenceClient
    let appLogger: Logger
    let getDateNow: GetDateNow
    let tagsActor: TagsActor
    let releaseMetadataActor: MemoryCacheActor<PersistenceClient.ReleaseMetadata>
    let manifestsActor: MemoryCacheActor<[PersistenceClient.Manifest]>
    let identifiersActor: IdentifiersActor

    init(
        serverURLString: String,
        clientSupportsPagination: Bool,
        githubAPIToken: String,
        githubAPIClient: GithubAPIClient,
        checksumClient: ChecksumClient,
        httpStreamClient: HTTPStreamClient,
        persistenceClient: PersistenceClient,
        appLogger: Logger,
        getDateNow: @escaping GetDateNow = { Date.now }
    ) {
        self.serverURLString = serverURLString
        self.clientSupportsPagination = clientSupportsPagination
        self.githubAPIToken = githubAPIToken
        self.githubAPIClient = githubAPIClient
        self.checksumClient = checksumClient
        self.httpStreamClient = httpStreamClient
        self.persistenceClient = persistenceClient
        self.appLogger = appLogger
        self.getDateNow = getDateNow

        let tagsActor = TagsActor { owner, repo, forceSync, reqLogger in
            try await Self.syncTags(
                owner: owner,
                repo: repo,
                forceSync: forceSync,
                persistenceClient: persistenceClient,
                githubAPIClient: githubAPIClient,
                logger: reqLogger,
                now: getDateNow
            )
        }

        let releaseMetadataActor = MemoryCacheActor { owner, repo, version, reqLogger in
            try await Self.syncReleaseMetadata(
                owner: owner,
                repo: repo,
                version: version,
                githubAPIClient: githubAPIClient,
                persistenceClient: persistenceClient,
                checksumClient: checksumClient,
                logger: reqLogger,
                tagsActor: tagsActor
            )
        }

        let manifestsActor = MemoryCacheActor { owner, repo, version, reqLogger in
            try await Self.syncManifests(
                owner: owner,
                repo: repo,
                version: version,
                persistenceClient: persistenceClient,
                githubAPIClient: githubAPIClient,
                tagsActor: tagsActor,
                logger: reqLogger
            )
        }

        let identifiersActor = IdentifiersActor { owner, repo, reqLogger in
            try await Self.fetchIsRepository(
                owner: owner,
                repo: repo,
                githubAPIClient: githubAPIClient,
                logger: reqLogger
            )
        }

        self.tagsActor = tagsActor
        self.releaseMetadataActor = releaseMetadataActor
        self.manifestsActor = manifestsActor
        self.identifiersActor = identifiersActor
    }

    func boot(routes: any RoutesBuilder) throws {
        let scopeName = routes.grouped(":scope", ":name")

        // List Package Releases
        scopeName.get(use: listPackageReleases)

        scopeName.group(":version") { scopeNameVersion in
            // Fetch Release Metadata or Download source archive
            scopeNameVersion.get(use: fetchReleaseMetadataOrDownloadSourceArchive)
            // Create Package Release
            scopeNameVersion.put(use: createPackageRelease)
            // Fetch Manifest
            scopeNameVersion.get("Package.swift", use: fetchManifest)
        }

        // Lookup Package Identifiers
        routes.get("identifiers", use: lookupPackageIdentifiers)

        // Login
        routes.post("login", use: login)
    }
}

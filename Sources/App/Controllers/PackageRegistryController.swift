import APIUtilities
import Dependencies
import ChecksumClient
import Fluent
import Foundation
import GithubAPIClient
import HTTPStreamClient
import PersistenceClient
import Vapor

struct PackageRegistryController: RouteCollection {
    typealias GetDateNow = @Sendable () -> Date

    let serverURLString: String
    let cacheRootDirectory: String
    let clientSupportsPagination: Bool
    let githubAPIToken: String
    let githubAPIClient: GithubAPIClient
    let checksumClient: ChecksumClient
    let httpStreamClient: HTTPStreamClient
    let persistenceClient: PersistenceClient
    let appLogger: Logger
    let getDateNow: GetDateNow
    let tagsActor: TagsActor
    let releaseMetadataActor: MemoryCacheActor<PackageReleaseMetadata>
    let manifestsActor: MemoryCacheActor<[CachedPackageManifest]>
    let identifiersActor: IdentifiersActor

    init(
        serverURLString: String,
        cacheRootDirectory: String,
        uuidGenerator: UUIDGenerator,
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
        self.cacheRootDirectory = cacheRootDirectory
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

        let databaseActor = DatabaseActor()

        let releaseMetadataActor = MemoryCacheActor { owner, repo, version, req in
            try await Self.syncReleaseMetadata(
                owner: owner,
                repo: repo,
                version: version,
                githubAPIClient: githubAPIClient,
                checksumClient: checksumClient,
                tagsActor: tagsActor,
                databaseActor: databaseActor,
                cacheRootDirectory: cacheRootDirectory,
                uuidGenerator: uuidGenerator,
                req: req
            )
        }

        let manifestsActor = MemoryCacheActor { owner, repo, version, req in
            try await Self.syncManifests(
                owner: owner,
                repo: repo,
                version: version,
                cacheRootDirectory: cacheRootDirectory,
                uuidGenerator: uuidGenerator,
                githubAPIClient: githubAPIClient,
                tagsActor: tagsActor,
                databaseActor: databaseActor,
                req: req
            )
        }

        let identifiersActor = IdentifiersActor { githubURL, reqLogger, database in
            try await Self.fetchPackageID(
                githubURL: githubURL,
                githubAPIClient: githubAPIClient,
                databaseActor: databaseActor,
                database: database,
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

private extension Repository {

    var githubURLs: [GithubURL] {
        [htmlGithubURL, cloneGithubURL, sshGithubURL].compactMap { $0 }
    }

    var htmlGithubURL: GithubURL? {
        GithubURL(urlString: htmlUrl)
    }
    var cloneGithubURL: GithubURL? {
        GithubURL(urlString: cloneUrl)
    }
    var sshGithubURL: GithubURL? {
        GithubURL(urlString: sshUrl)
    }
}

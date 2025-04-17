import Fluent
import Foundation
import GithubAPIClient
import Semaphore
import Vapor

actor DatabaseActor {
    private let repositorySemaphore = AsyncSemaphore(value: 1)
    private let manifestsSemaphore = AsyncSemaphore(value: 1)

    func addRepository(
        _ repository: GithubAPIClient.Repository,
        logger: Logger,
        database: any Database
    ) async throws {
        await repositorySemaphore.wait()
        defer { repositorySemaphore.signal() }

        try await _addRepository(repository, logger: logger, database: database)
    }

    private func _addRepository(_ repository: GithubAPIClient.Repository, logger: Logger, database: any Database) async throws {
        // Query to see if we already a repository with this Github repository id
        let repositoryWithIdCount = try await Repository.query(on: database)
            .filter(\.$id == repository.id)
            .count()
        guard repositoryWithIdCount == 0 else {
            logger.debug("Repository with id=\(repository.id) already exists in database. Skipping database add.")
            return
        }

        let repositoryToAdd = Repository(
            id: repository.id,
            htmlUrl: repository.htmlURL,
            cloneUrl: repository.cloneURL,
            sshUrl: repository.sshURL
        )
        logger.debug("Adding repository (id=\(repository.id), packageID=\"\(repository.packageID)\") to database.")
        try await repositoryToAdd.create(on: database)
        logger.debug("Added repository (id=\(repository.id), packageID=\"\(repository.packageID)\") to database.")
    }

    func addCachedPackageManifests(
        _ manifests: [CachedPackageManifest],
        logger: Logger,
        database: any Database
    ) async throws {
        await manifestsSemaphore.wait()
        defer { manifestsSemaphore.signal() }

        try await _addCachedPackageManifests(manifests, logger: logger, database: database)
    }

    private func _addCachedPackageManifests(
        _ cachedPackageManifests: [CachedPackageManifest],
        logger: Logger,
        database: any Database
    ) async throws {
        // Validate the array of CachedPackageManifest
        guard Self.validateCachedPackageManifests(cachedPackageManifests, logger: logger) else {
            logger.error("CachedPackageManifests failed validation.")
            return
        }
        try await withThrowingTaskGroup(of: Void.self) { group in
            cachedPackageManifests.forEach { cachedPackageManifest in
                group.addTask {
                    try await Self.addCachedPackageManifestToDatabase(
                        cachedPackageManifest,
                        logger: logger,
                        database: database
                    )
                }
            }
            try await group.waitForAll()
        }
    }

    private static func validateCachedPackageManifests(
        _ cachedPackageManifests: [CachedPackageManifest],
        logger: Logger
    ) -> Bool {
        // Make sure we actually have some manifests to add
        guard !cachedPackageManifests.isEmpty else {
            logger.error("No manifests to add to DB. Exiting.")
            return false
        }
        // Make sure all of the CachedPackageManifest have the same package scope, name, and version.
        guard
            cachedPackageManifests.map(\.packageManifest.packageScope).allSame,
            cachedPackageManifests.map(\.packageManifest.packageName).allSame,
            cachedPackageManifests.map(\.packageManifest.packageVersion).allSame
        else {
            logger.error("Manifests do not all have the same scope, name, and version. Exiting.")
            return false
        }

        // Make sure that the swiftVersion for each CachedPackageManifest is different
        guard cachedPackageManifests.map(\.packageManifest.nonNullSwiftVersion).allUnique else {
            logger.error("More than one CachedPackageManifest have the same swiftVersion. Exiting.")
            return false
        }

        return true
    }

    private static func addCachedPackageManifestToDatabase(
        _ cachedPackageManifest: CachedPackageManifest,
        logger: Logger,
        database: any Database
    ) async throws {
        // Attempt to read in package manifests from db that match this one
        let manifests = try await Manifest.query(on: database)
            .filter(\.$packageScope == cachedPackageManifest.packageManifest.packageScope)
            .filter(\.$packageName == cachedPackageManifest.packageManifest.packageName)
            .filter(\.$packageVersion == cachedPackageManifest.packageManifest.packageVersion)
            .filter(\.$swiftVersion == cachedPackageManifest.packageManifest.swiftVersion)
            .all()
        guard manifests.isEmpty else {
            logger.error("Existing package manifest in DB. Exiting.")
            return
        }
        // Add the CachedPackageManifest to the database
        let manifestToAdd = Manifest(cachedPackageManifest: cachedPackageManifest)
        logger.debug("Adding manifest to database: \(manifestToAdd).")
        try await manifestToAdd.create(on: database)
        logger.debug("Added manifest to database: \(manifestToAdd).")
    }
}

private extension PackageManifest {
    var nonNullSwiftVersion: String {
        swiftVersion ?? "nullSwiftVersion"
    }
}

private extension Array where Element == String {
    var allSame: Bool {
        guard let first else { return false }
        return allSatisfy { $0 == first }
    }
    var allUnique: Bool {
        var set = Set<String>()
        for value in self {
            if set.contains(value) {
                return false
            }
            set.insert(value)
        }
        return true
    }
}

private extension Manifest {
    convenience init(cachedPackageManifest: CachedPackageManifest) {
        self.init(
            packageScope: cachedPackageManifest.packageManifest.packageScope,
            packageName: cachedPackageManifest.packageManifest.packageName,
            packageVersion: cachedPackageManifest.packageManifest.packageVersion,
            swiftVersion: cachedPackageManifest.packageManifest.swiftVersion,
            swiftToolsVersion: cachedPackageManifest.packageManifest.swiftToolsVersion,
            cacheFileName: cachedPackageManifest.cacheFileName
        )
    }
}

extension Manifest: CustomStringConvertible {
    var description: String {
        "Manifest(\(packageScope),\(packageName),\(packageVersion),\(swiftVersion ?? "nil"),\(swiftToolsVersion),\(cacheFileName))"
    }
}

import Fluent
import Foundation
import GithubAPIClient
import Semaphore
import Vapor

actor DatabaseActor {
    private let semaphore = AsyncSemaphore(value: 1)

    func addRepository(_ repository: GithubAPIClient.Repository, logger: Logger, database: any Database) async throws {
        await semaphore.wait()
        defer { semaphore.signal() }

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
}

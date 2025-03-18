import Foundation
import PersistenceClient
import Semaphore
import Vapor

actor RepositoriesFileActor {
    private let persistenceClient: PersistenceClient
    private let semaphore = AsyncSemaphore(value: 1)

    init(persistenceClient: PersistenceClient) {
        self.persistenceClient = persistenceClient
    }

    func addRepository(_ repository: PersistenceClient.Repository) async throws {
        await semaphore.wait()
        defer { semaphore.signal() }

        try await _addRepository(repository)
    }

    private func _addRepository(_ repository: PersistenceClient.Repository) async throws {
        // Read the current repository file
        var repositoryFile = try await persistenceClient.readRepositories()
        // Verify we don't already have a respository with the given id
        guard !repositoryFile.repositories.contains(where: { $0.id == repository.id }) else {
            // We were attempting to add a duplicate repository, so early exit
            return
        }
        // Add the repository
        repositoryFile.repositories.append(repository)
        // Sort by packageID
        repositoryFile.repositories.sort { $0.packageID < $1.packageID }
        // Update the lastUpdatedAt date
        repositoryFile.lastUpdatedAt = Date.now
        // Write out the updated file
        try await persistenceClient.saveRepositories(repositoryFile)
    }
}

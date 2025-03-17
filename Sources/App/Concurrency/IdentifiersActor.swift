import Foundation
import Vapor

/// This actor accomplishes two purposes:
/// - Holds a memory cache of `Bool`, keyed by package id
/// - Ensures that for a specific package id, we only execute one `IsRepositoryLoader` at a time.
///
/// Since `IsRepositoryLoader` may mutate the disk cache, then this eliminates the race condition where two requests to the same package id
/// could be attempting to read and write to the disk cache simultaneously.
actor IdentifiersActor {
    typealias IsRepositoryLoader = @Sendable (_ owner: String, _ repo: String, _ logger: Logger) async throws -> Bool

    private var memoryCache: [String: IsRepositoryState] = [:]
    private let isRepositoryLoader: IsRepositoryLoader

    init(isRepositoryLoader: @escaping IsRepositoryLoader) {
        self.isRepositoryLoader = isRepositoryLoader
    }

    func isRepository(owner: String, repo: String, logger: Logger) async throws -> Bool {
        let cacheKey = Self.makeCacheKey(owner, repo)
        if let state = memoryCache[cacheKey] {
            switch state {
            case .loaded(let isRepository):
                logger.debug("IsRepository=\(isRepository) found in memory cache for \(cacheKey).")
                return isRepository
            case .loading(let task):
                logger.debug("IsRepository flag is loading for \(cacheKey). Awaiting loading task.")
                return try await task.value
            }
        }

        let task = Task {
            try await isRepositoryLoader(owner, repo, logger)
        }

        memoryCache[cacheKey] = .loading(task)

        do {
            let isRepository = try await task.value
            memoryCache[cacheKey] = .loaded(isRepository)
            logger.debug("Loaded IsRepository=\(isRepository) from isRepositoryLoader for \(cacheKey)")
            return isRepository
        } catch {
            memoryCache[cacheKey] = nil
            logger.error("isRepositoryLoader threw an error for \(cacheKey): \(error)")
            throw error
        }
    }

    private static func makeCacheKey(_ owner: String, _ repo: String) -> String {
        "\(owner.lowercased()).\(repo.lowercased())"
    }

    private enum IsRepositoryState {
        case loading(Task<Bool, Error>)
        case loaded(Bool)
    }
}

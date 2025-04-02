import APIUtilities
import Vapor

/// This actor accomplishes two purposes:
/// - Holds a memory cache of generic data, keyed by `owner`, `repo`, and `version`
/// - Ensures that for a specific cache key, we only execute one `DataLoader` at a time.
///
/// Since `DataLoader` may mutate the disk cache, then this eliminates the race condition where two requests to the same owner/repo/version
/// could be attempting to read and write to the disk cache simultaneously. So if we get two simultaneous requests
/// with same `owner`, `repo`, and `version` for both requests, then the second one must will wait on the first one
/// to complete before it completes.
actor MemoryCacheActor<T: Equatable & Sendable & Codable> {
    typealias DataLoader = @Sendable (_ owner: String, _ repo: String, _ version: Version, _ logger: Logger) async throws -> T

    private var memoryCache: [String: ReleaseMetadataState] = [:]
    private let dataLoader: DataLoader

    init(dataLoader: @escaping DataLoader) {
        self.dataLoader = dataLoader
    }

    func loadData(owner: String, repo: String, version: Version, logger: Logger) async throws -> T {
        let cacheKey = Self.makeCacheKey(owner, repo, version)
        if let state = memoryCache[cacheKey] {
            switch state {
            case .loaded(let data):
                logger.debug("Loaded \(T.self) from memory cache for \(cacheKey)")
                return data
            case .loading(let task):
                logger.debug("\(T.self) memory cache is loading for \(cacheKey). Awaiting loading task.")
                return try await task.value
            }
        }

        let task = Task {
            try await dataLoader(owner, repo, version, logger)
        }

        memoryCache[cacheKey] = .loading(task)

        do {
            let data = try await task.value
            memoryCache[cacheKey] = .loaded(data)
            logger.debug("Loaded \(T.self) from dataLoader for \(cacheKey)")
            return data
        } catch {
            memoryCache[cacheKey] = nil
            logger.error("\(T.self) dataLoader threw an error for \(cacheKey): \(error)")
            throw error
        }
    }

    private static func makeCacheKey(_ owner: String, _ repo: String, _ version: Version) -> String {
        "\(owner.lowercased())_\(repo.lowercased())_\(version)"
    }

    private enum ReleaseMetadataState {
        case loading(Task<T, Error>)
        case loaded(T)
    }
}

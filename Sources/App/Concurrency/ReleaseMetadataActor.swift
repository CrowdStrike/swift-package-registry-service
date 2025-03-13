import APIUtilities
import PersistenceClient
import Vapor

/// This actor accomplishes two purposes:
/// - Holds a memory cache of `PersistenceClient.ReleaseMetadata`, keyed by `owner`, `repo`, and `version`
/// - Ensures that for a specific cache key, we only execute one `TagFileLoader` at a time.
///
/// Since `ReleaseMetadataLoader` may mutate the disk cache, then this eliminates the race condition where two requests to the same owner/repo/version
/// could be attempting to read and write to the disk cache simultaneously. So if we get two simultaneous requests to
/// `GET /:owner/:repo/:version` with same `owner`, `repo`, and `version` for both requests, then the second one must
/// will wait on the first one to complete before it completes.
actor ReleaseMetadataActor {
    typealias ReleaseMetadataLoader = @Sendable (_ owner: String, _ repo: String, _ version: Version) async throws -> PersistenceClient.ReleaseMetadata

    private var memoryCache: [String: ReleaseMetadataState] = [:]
    private let releaseMetadataLoader: ReleaseMetadataLoader

    init(releaseMetadataLoader: @escaping ReleaseMetadataLoader) {
        self.releaseMetadataLoader = releaseMetadataLoader
    }

    func loadReleaseMetadata(owner: String, repo: String, version: Version, logger: Logger) async throws -> PersistenceClient.ReleaseMetadata {
        let cacheKey = Self.makeCacheKey(owner, repo, version)
        if let state = memoryCache[cacheKey] {
            switch state {
            case .loaded(let releaseMetadata):
                logger.debug("Loaded ReleaseMetadata from memory cache for \(cacheKey)")
                return releaseMetadata
            case .loading(let task):
                logger.debug("ReleaseMetadata memory cache is loading for \(cacheKey). Awaiting loading task.")
                return try await task.value
            }
        }

        let task = Task {
            try await releaseMetadataLoader(owner, repo, version)
        }

        memoryCache[cacheKey] = .loading(task)

        do {
            let releaseMetadata = try await task.value
            memoryCache[cacheKey] = .loaded(releaseMetadata)
            logger.debug("Loaded ReleaseMetadata from releaseMetadataLoader for \(cacheKey)")
            return releaseMetadata
        } catch {
            memoryCache[cacheKey] = nil
            logger.error("releaseMetadataLoader threw an error for \(cacheKey): \(error)")
            throw error
        }
    }

    private static func makeCacheKey(_ owner: String, _ repo: String, _ version: Version) -> String {
        "\(owner.lowercased())_\(repo.lowercased())_\(version)"
    }

    private enum ReleaseMetadataState {
        case loading(Task<PersistenceClient.ReleaseMetadata, Error>)
        case loaded(PersistenceClient.ReleaseMetadata)
    }
}

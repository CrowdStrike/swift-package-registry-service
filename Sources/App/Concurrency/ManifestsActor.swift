import APIUtilities
import PersistenceClient
import Vapor

/// This actor accomplishes two purposes:
/// - Holds a memory cache of `[PersistenceClient.Manifest]`, keyed by `owner`, `repo`, and `version`
/// - Ensures that for a specific cache key, we only execute one `ManifestsLoader` at a time.
///
/// Since `ManifestsLoader` may mutate the disk cache, then this eliminates the race condition where two requests to the same
/// owner/repo/version could be attempting to read and write to the disk cache simultaneously. So if we get two simultaneous requests to
/// `GET /:owner/:repo/:version/Package.swift` with same `owner`, `repo`, and `version` for both requests,
/// then the second one must will wait on the first one to complete before it completes.
actor ManifestsActor {
    typealias ManifestsLoader = @Sendable (_ owner: String, _ repo: String, _ version: Version, _ logger: Logger) async throws -> [PersistenceClient.Manifest]

    private var memoryCache: [String: ManifestsState] = [:]
    private let manifestsLoader: ManifestsLoader

    init(manifestsLoader: @escaping ManifestsLoader) {
        self.manifestsLoader = manifestsLoader
    }

    func loadManifests(owner: String, repo: String, version: Version, logger: Logger) async throws -> [PersistenceClient.Manifest] {
        let cacheKey = Self.makeCacheKey(owner, repo, version)
        if let state = memoryCache[cacheKey] {
            switch state {
            case .loaded(let manifests):
                logger.debug("Loaded \(manifests.count) manifests from memory cache for \(cacheKey)")
                return manifests
            case .loading(let task):
                logger.debug("Manifests memory cache is loading for \(cacheKey). Awaiting loading task.")
                return try await task.value
            }
        }

        let task = Task {
            try await manifestsLoader(owner, repo, version, logger)
        }

        memoryCache[cacheKey] = .loading(task)

        do {
            let manifests = try await task.value
            memoryCache[cacheKey] = .loaded(manifests)
            logger.debug("Loaded \(manifests.count) manifests from manifestsLoader for \(cacheKey)")
            return manifests
        } catch {
            memoryCache[cacheKey] = nil
            logger.error("manifestsLoader threw an error for \(cacheKey): \(error)")
            throw error
        }
    }

    private static func makeCacheKey(_ owner: String, _ repo: String, _ version: Version) -> String {
        "\(owner.lowercased())_\(repo.lowercased())_\(version)"
    }

    private enum ManifestsState {
        case loading(Task<[PersistenceClient.Manifest], Error>)
        case loaded([PersistenceClient.Manifest])
    }
}

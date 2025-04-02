import Foundation
import PersistenceClient
import Vapor

/// This actor accomplishes two purposes:
/// - Holds a memory cache of `PersistenceClient.TagFile`, keyed by package id
/// - Ensures that for a specific package id, we only execute one `TagFileLoader` at a time.
///
/// Since `TagFileLoader` may mutate the disk cache, then this eliminates the race condition where two requests to the same package id
/// could be attempting to read and write to the disk cache simultaneously. So if we get two simultaneous requests to
/// `GET /:owner/:repo` with same `owner` and `repo` for both requests, then the second one must
/// will wait on the first one to complete before it completes.
actor TagsActor {
    typealias TagFileLoader = @Sendable (_ owner: String, _ repo: String, _ forceSync: Bool, _ logger: Logger) async throws -> PersistenceClient.TagFile
    typealias GetDateNow = () -> Date

    private var memoryCache: [String: TagFileState] = [:]
    private let tagFileLoader: TagFileLoader
    private let memoryCacheExpiration: TimeInterval
    private let getDateNow: GetDateNow
    static let defaultMemoryCacheExpiration: TimeInterval = 60 * 5 // 5 minutes

    init(
        memoryCacheExpiration: TimeInterval = defaultMemoryCacheExpiration,
        getDateNow: @escaping GetDateNow = { Date.now },
        tagFileLoader: @escaping TagFileLoader
    ) {
        self.memoryCacheExpiration = memoryCacheExpiration
        self.getDateNow = getDateNow
        self.tagFileLoader = tagFileLoader
    }

    func loadTagFile(owner: String, repo: String, forceSync: Bool, logger: Logger) async throws -> PersistenceClient.TagFile {
        let cacheKey = Self.makeCacheKey(owner, repo)
        if let state = memoryCache[cacheKey] {
            switch state {
            case let .loaded(tagFile, cachedDate):
                if getDateNow().timeIntervalSince(cachedDate) < memoryCacheExpiration {
                    logger.debug("Loaded \(tagFile.tags.count) tags from memory cache for \(cacheKey)")
                    return tagFile
                } else {
                    logger.debug("TagFile expired in memory cache for \(cacheKey)")
                }
            case .loading(let task):
                logger.debug("TagFile memory cache is loading for \(cacheKey). Awaiting loading task.")
                return try await task.value
            }
        }

        let task = Task {
            try await tagFileLoader(owner, repo, forceSync, logger)
        }

        memoryCache[cacheKey] = .loading(task)

        do {
            let tagFile = try await task.value
            memoryCache[cacheKey] = .loaded(tagFile, getDateNow())
            logger.debug("Loaded \(tagFile.tags.count) tags from tagFileLoader for \(cacheKey)")
            return tagFile
        } catch {
            memoryCache[cacheKey] = nil
            logger.error("tagFileLoader threw an error for \(cacheKey): \(error)")
            throw error
        }
    }

    private static func makeCacheKey(_ owner: String, _ repo: String) -> String {
        "\(owner.lowercased()).\(repo.lowercased())"
    }

    private enum TagFileState {
        case loading(Task<PersistenceClient.TagFile, Error>)
        case loaded(PersistenceClient.TagFile, Date)
    }
}

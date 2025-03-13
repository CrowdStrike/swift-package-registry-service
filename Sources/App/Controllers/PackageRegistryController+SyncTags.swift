import APIUtilities
import FileClient
import GithubAPIClient
import PersistenceClient
import Vapor

extension PackageRegistryController {
    private static let minimumSyncInterval: TimeInterval = 60 * 5 // 5 minutes

    static func syncTags(
        owner: String,
        repo: String,
        forceSync: Bool,
        persistenceClient: PersistenceClient,
        githubAPIClient: GithubAPIClient,
        logger: Logger,
        now: () -> Date
    ) async throws -> PersistenceClient.TagFile {
        // Attempt to read the cached tags (this may fail if we have never fetched before).
        var tagFile = PersistenceClient.TagFile()
        let readFile: Bool
        do {
            tagFile = try await persistenceClient.readTags(owner: owner, repo: repo)
            logger.debug("Fetched \(tagFile.tags.count) cached tags for \(owner).\(repo). Cache last updated at \(tagFile.lastUpdatedAt).")
            readFile = true
        } catch let fileClientError as FileClientError {
            switch fileClientError {
            case .fileNotFound:
                logger.debug("No tag cache file found for \(owner).\(repo)")
                readFile = false
            }
        } catch {
            throw error
        }

        // Check if we should sync or just return
        let minimumSyncDurationExceeded = now().timeIntervalSince(tagFile.lastUpdatedAt) > Self.minimumSyncInterval
        let shouldSync = forceSync || minimumSyncDurationExceeded || !readFile || tagFile.tags.isEmpty
        guard shouldSync else {
            logger.debug("Tag sync will not be performed for \(owner).\(repo). Returning \(tagFile.tags.count) cached tags.")
            return tagFile
        }

        if !tagFile.tags.isEmpty {
            let tagNameSet = Set(tagFile.tags.map(\.name))
            // Fetch 1 tag from the Github API.
            let firstTagInput = GithubAPIClient.ListRepositoryTags.Input(owner: owner, repo: repo, perPage: 1, page: 1)
            if let firstTag = try await githubAPIClient.listRepositoryTags(firstTagInput).tags.first, tagNameSet.contains(firstTag.name) {
                // The first tag was already cached.
                // We assume that the Github API returns us tags in newest-to-oldest order.
                // So if the first tag is already cached, then we terminate the sync early.
                logger.debug("First tag \"\(firstTag.name)\" for \(owner).\(repo) is already cached.  Returning \(tagFile.tags.count) cached tags.")
                return tagFile
            }
        }
        // Now we must do a full page-by-page sync.
        var tags = [PersistenceClient.Tag]()
        var tagsInput = GithubAPIClient.ListRepositoryTags.Input(owner: owner, repo: repo)
        var tagsOutput = GithubAPIClient.ListRepositoryTags.Output.mock
        var nextPage: APIUtilities.PageInfo? = .init(perPage: 100, page: 1)
        while nextPage != nil {
            tagsInput.updatePageInfo(nextPage!)
            logger.debug("Fetching tags page \(tagsInput.page ?? 1) for \(owner).\(repo)")
            tagsOutput = try await githubAPIClient.listRepositoryTags(tagsInput)
            let fetchedTags = try tagsOutput.tags.map(\.asTag)
            logger.debug("Fetched \(fetchedTags.count) tags in page \(tagsInput.page ?? 1) for \(owner).\(repo)")
            tags.append(contentsOf: fetchedTags)
            nextPage = tagsOutput.nextPage
        }
        // Compute the Version to Tag map
        let versionToTagName = Version.versionToTagMap(fromTags: tags.map(\.name))
        // Persist the tag file
        logger.debug("Persisting \(tags.count) tags for \(owner).\(repo)")
        tagFile = .init(lastUpdatedAt: Date.now, tags: tags, versionToTagName: versionToTagName)
        try await persistenceClient.saveTags(owner: owner, repo: repo, tagFile: tagFile)

        return tagFile
    }
}

extension GithubAPIClient.ListRepositoryTags.Output {
    var tags: [GithubAPIClient.ListRepositoryTags.OKBody.Tag] {
        get throws {
            switch self {
            case .ok(let okBody):
                return okBody.tags
            case .other(let httpResponse):
                throw Abort(.init(statusCode: httpResponse.status.code))
            }
        }
    }
}

extension GithubAPIClient.ListRepositoryTags.OKBody.Tag {
    var asTag: PersistenceClient.Tag {
        .init(name: name, nodeId: nodeId, sha: sha, zipBallURL: zipBallURL, apiLexicalOrder: apiLexicalOrder)
    }
}

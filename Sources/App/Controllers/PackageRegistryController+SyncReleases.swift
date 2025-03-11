import APIUtilities
import GithubAPIClient
import PersistenceClient
import Vapor

extension PackageRegistryController {
    func syncReleases(owner: String, repo: String) async throws -> [PersistenceClient.Release] {
        // Attempt to read the cached releases (this may fail if we have never fetched before).
        var releases: [PersistenceClient.Release]
        do {
            releases = try await persistenceClient.readReleases(owner: owner, repo: repo)
            logger.debug("Fetched \(releases.count) cached releases for \(owner).\(repo)")
        } catch {
            logger.debug("No releases cached for \(owner).\(repo)")
            releases = []
        }
        var idSet = Set(releases.map(\.tagName))
        // If we have cached any releases that are not from tags, then call the Github API to fetch the latest release.
        if releases.count(where: { !$0.fromTag }) > 0 {
            // Get the latest release.
            let latestRelease = try await githubAPIClient.getLatestRelease(.init(owner: owner, repo: repo)).release
            if idSet.contains(latestRelease.tagName) {
                // We already have the latest release cached, so we can early exit,
                // and return our cached releases.
                logger.debug("Latest release for \(owner).\(repo) (tagName=\(latestRelease.tagName)) is already cached. Exiting syncReleases() early.")
                return releases
            }
        }
        let cachedCount = releases.count

        // We didn't have the latest release cached, so we need to do a page-by-page sync.
        var clientInput = GithubAPIClient.RepositoryListReleases.Input(owner: owner, repo: repo)
        var clientOutput: GithubAPIClient.RepositoryListReleases.Output
        var nextPage: APIUtilities.PageInfo? = .init(perPage: 100, page: 1)
        let parser = SemanticVersionParser()
        while nextPage != nil {
            clientInput.updatePageInfo(nextPage!)
            logger.debug("Fetching page \(clientInput.page ?? 1) for \(owner).\(repo)")
            clientOutput = try await githubAPIClient.repositoryListReleases(clientInput)
            let fetchedReleases = try clientOutput.releases.map { try $0.toRelease(owner: owner, repo: repo, parser: parser) }
            let releasesToAppend = fetchedReleases.filter { !idSet.contains($0.tagName) }
            logger.debug("Fetched \(fetchedReleases.count) releases for \(owner).\(repo). \(releasesToAppend.count) were not cached.")
            if !releasesToAppend.isEmpty {
                releases.append(contentsOf: releasesToAppend)
                releasesToAppend.forEach { idSet.insert($0.tagName) }
            }
            if releasesToAppend.count < fetchedReleases.count {
                // This page of fetched releases contained a release that we had
                // already cached, so since we assume that the API returns releases to
                // us in newest-to-oldest order, then we can early terminate, since
                // we can therefore assume that all of the rest of the fetched
                // releases will also have been cached.
                break
            }
            nextPage = clientOutput.nextPage
        }
        // A few repositories don't have releases, but only tags.
        // So we must also fetch all the tags, and create PersistenceClient.Release
        // objects from the tags that don't have corresponding releases.
        var tagsInput = GithubAPIClient.ListRepositoryTags.Input(owner: owner, repo: repo)
        var tagsOutput: GithubAPIClient.ListRepositoryTags.Output
        nextPage = .init(perPage: 100, page: 1)
        while nextPage != nil {
            tagsInput.updatePageInfo(nextPage!)
            logger.debug("Fetching tags page \(tagsInput.page ?? 1) for \(owner).\(repo)")
            tagsOutput = try await githubAPIClient.listRepositoryTags(tagsInput)
            let fetchedReleases = try tagsOutput.tags.map { try $0.toRelease(owner: owner, repo: repo, parser: parser) }
            let releasesToAppend = fetchedReleases.filter { !idSet.contains($0.tagName) }
            logger.debug("Fetched \(fetchedReleases.count) tags for \(owner).\(repo). \(releasesToAppend.count) were not cached.")
            if !releasesToAppend.isEmpty {
                releases.append(contentsOf: releasesToAppend)
                releasesToAppend.forEach { idSet.insert($0.tagName) }
            }
            if releasesToAppend.count < fetchedReleases.count {
                // This page of fetched tags contained a tag that we had
                // already cached, so since we assume that the API returns releases to
                // us in newest-to-oldest order, then we can early terminate, since
                // we can therefore assume that all of the rest of the fetched
                // releases will also have been cached.
                break
            }
            nextPage = tagsOutput.nextPage
        }
        // Sort the releases from newest-to-oldest
        releases.sort(by: >)
        // Persist (if necessary)
        if releases.count > cachedCount {
            // Persist the updated releases
            logger.debug("Added \(releases.count - cachedCount) releases to the cache - saving...")
            try await persistenceClient.saveReleases(releases: releases)
        }
        return releases
    }
}

extension GithubAPIClient.GetLatestRelease.Output {
    var release: GithubAPIClient.Release {
        get throws {
            switch self {
            case .ok(let release):
                return release
            case .other(let statusCode):
                throw Abort(.init(statusCode: statusCode))
            }
        }
    }
}

extension GithubAPIClient.RepositoryListReleases.Output {
    var releases: [GithubAPIClient.Release] {
        get throws {
            switch self {
            case .ok(let oKBody):
                oKBody.releases
            case .notFound:
                throw Abort(.notFound)
            case .other(let statusCode):
                throw Abort(.init(statusCode: statusCode))
            }
        }
    }
}

extension GithubAPIClient.Release {
    func toRelease(owner: String, repo: String, parser: SemanticVersionParser) throws -> PersistenceClient.Release {
        .init(
            owner: owner,
            repo: repo,
            tagName: tagName,
            id: id,
            name: name,
            createdAt: createdAt,
            publishedAt: publishedAt,
            semanticVersion: try parser.semVerString(from: tagName),
            zipBallURL: zipBallURL
        )
    }
}

extension GithubAPIClient.ListRepositoryTags.OKBody.Tag {
    func toRelease(owner: String, repo: String, parser: SemanticVersionParser) throws -> PersistenceClient.Release {
        .init(
            owner: owner,
            repo: repo,
            tagName: name,
            id: 0,
            name: name,
            semanticVersion: try parser.semVerString(from: name),
            zipBallURL: zipBallURL,
            fromTag: true
        )
    }
}

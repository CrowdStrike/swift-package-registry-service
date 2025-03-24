import APIUtilities
import ChecksumClient
import Fluent
import GithubAPIClient
import PersistenceClient
import Vapor

extension PackageRegistryController {

    static func fetchPackageID(
        githubURL: GithubURL,
        githubAPIClient: GithubAPIClient,
        databaseActor: DatabaseActor,
        database: any Database,
        logger: Logger
    ) async throws -> String? {
        logger.debug("Calling Github API GetRepository to fetch repository info for \"\(githubURL)\"...")
        // Call the GET /repos/{owner}/{repo} Github API endpoint to fetch the repository info.
        let repository = try await githubAPIClient
            .getRepository(.init(owner: githubURL.scope, repo: githubURL.name))
            .toRepository(ownerFromRequest: githubURL.scope)

        guard let repository else {
            // The GithubAPIClient did not throw an error, but returned nil.
            // This means that the GithubAPI returned a 404 Not Found, which
            // would be the expected result when no such owner/repo pair was found.
            // So we don't throw an error, but just return nil.
            logger.debug("GitubAPIClient returned nil repository for \"\(githubURL)\", so returning nil.")
            return nil
        }
        logger.debug("Github GetRepository returned repository with github_id=\(repository.id)")

        // Add this repository to the database
        try await databaseActor.addRepository(repository, logger: logger, database: database)

        logger.debug("Added repository with github_id=\(repository.id) to database.")

        return repository.packageID
    }
}

extension GithubAPIClient.GetRepository.Output {

    func toRepository(ownerFromRequest: String) throws -> PersistenceClient.Repository? {
        switch self {
        case .ok(let okBody):
            return okBody.toRepository(ownerFromRequest: ownerFromRequest)
        case .movedPermanently:
            // TODO: handle this differently
            throw Abort(.movedPermanently)
        case .notFound:
            return nil
        case .forbidden:
            throw Abort(.forbidden)
        case .other(let statusCode):
            throw Abort(.init(statusCode: statusCode))
        }
    }
}

extension GithubAPIClient.GetRepository.Output.OKBody {

    func toRepository(ownerFromRequest: String) -> PersistenceClient.Repository {
        .init(
            id: id,
            owner: owner ?? ownerFromRequest,
            name: name,
            cloneURL: cloneURL,
            sshURL: sshURL,
            htmlURL: htmlURL
        )
    }
}

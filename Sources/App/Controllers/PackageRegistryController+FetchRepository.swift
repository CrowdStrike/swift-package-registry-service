import APIUtilities
import ChecksumClient
import GithubAPIClient
import PersistenceClient
import Vapor

extension PackageRegistryController {

    static func fetchIsRepository(
        owner: String,
        repo: String,
        githubAPIClient: GithubAPIClient,
        logger: Logger
    ) async throws -> Bool {
        // Call the GET /repos/{owner}/{repo} Github API endpoint.
        return try await githubAPIClient.getRepository(.init(owner: owner, repo: repo)).isRepository
    }
}

extension GithubAPIClient.GetRepository.Output {

    var isRepository: Bool {
        get throws {
            switch self {
            case .ok, .movedPermanently:
                return true
            case .notFound:
                return false
            case .forbidden:
                throw Abort(.forbidden, title: "Forbidden")
            case .other(let statusCode):
                throw Abort(.init(statusCode: statusCode))
            }
        }
    }
}

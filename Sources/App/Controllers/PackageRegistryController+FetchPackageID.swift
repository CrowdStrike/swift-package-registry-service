import APIUtilities
import ChecksumClient
import GithubAPIClient
import PersistenceClient
import Vapor

extension PackageRegistryController {

    static func fetchPackageID(
        url: String,
        githubAPIClient: GithubAPIClient,
        logger: Logger
    ) async throws -> String? {
        // Parse this URL as either an HTTPS or SSH Github URL
        guard let githubURL = GithubURL(urlString: url) else {
            // This is not a Github URL, so we just return a nil packageID
            return nil
        }

        // Call the GET /repos/{owner}/{repo} Github API endpoint.
        let repository = try await githubAPIClient.getRepository(.init(owner: githubURL.scope, repo: githubURL.name))
            .toRepository(ownerFromRequest: githubURL.scope)

        guard let repository else {
            // The GithubAPIClient did not throw an error, but returned nil.
            // This means that the GithubAPI returned a 404 Not Found, which
            // would be the expected result when no such owner/repo pair was found.
            // So we don't throw an error, but just return nil.
            return nil
        }

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

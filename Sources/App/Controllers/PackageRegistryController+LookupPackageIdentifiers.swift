import APIUtilities
import GithubAPIClient
import Vapor

extension PackageRegistryController {

    func lookupPackageIdentifiers(req: Request) async throws -> LookupPackageIdentifiers {
        let queryParams = try req.query.decode(LookupPackageIdentifiersQueryParameters.self)
        try req.checkAcceptHeader(expectedMediaType: .json)

        // If we don't have an "url" query param, then we respond with 400 Bad Request.
        guard let url = queryParams.url, !url.isEmpty else {
            throw Abort(.badRequest, title: "Missing query parameter 'url'")
        }

        // If this URL doesn't parse in one of these forms, then reject it:
        // - An "HTML URL": "https://github.com/<scope>/<name>"
        // - A "Clone URL": "https://github.com/<scope>/<name>.git"
        // - An "SSH URL": "git@github.com:<scope>/<name>.git"
        guard let githubURL = GithubURL(urlString: url) else {
            req.logger.debug("\"\(url)\" is not a Github URL. Returning 404 Not Found.")
            throw Abort(.notFound, title: "Not a Github URL.")
        }

        // Look up the packageID
        let packageID = try await identifiersActor.loadPackageID(
            githubURL: githubURL,
            logger: req.logger,
            database: req.db
        )

        guard let packageID else {
            // The Github API said it did not find a repository with this owner and repo.
            throw Abort(.notFound, title: "No such repository found.")
        }

        return .init(identifiers: [packageID])
    }

    private struct LookupPackageIdentifiersQueryParameters: Content {
        var url: String?
    }
}

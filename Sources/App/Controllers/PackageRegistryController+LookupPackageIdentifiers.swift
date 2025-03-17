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

        // Look up the packageID
        let packageID = try await identifiersActor.loadPackageID(url: url, logger: req.logger)

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

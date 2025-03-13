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

        // Parse this URL as either an HTTPS or SSH Github URL
        guard let githubURL = GithubURL(urlString: url) else {
            // This is not a Github URL, so we respond with a 404.
            throw Abort(.notFound, title: "URL does not appear to be a valid Github URL")
        }

        // Get the cached tag information.
        // TODO: Look for lighter-weight solution instead of full tag sync.
        let tagFile = try await tagsActor.loadTagFile(owner: githubURL.scope, repo: githubURL.name, forceSync: false)

        guard !tagFile.tags.isEmpty else {
            // We do not have any tag for this repo.
            throw Abort(.notFound, title: "URL cannot be resolved with Github.")
        }

        return .init(
            identifiers: [
                githubURL.packageIdentifier
            ]
        )
    }

    private struct LookupPackageIdentifiersQueryParameters: Content {
        var url: String?
    }
}

extension GithubAPIClient.ListRepositoryTags.Output {

    var isOK: Bool {
        switch self {
        case .ok: true
        default: false
        }
    }
}

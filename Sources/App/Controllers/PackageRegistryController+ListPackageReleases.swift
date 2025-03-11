import APIUtilities
import GithubAPIClient
import HTTPTypes
import PersistenceClient
import Vapor

extension PackageRegistryController {
    func listPackageReleases(req: Request) async throws -> ListPackageReleases {
        let packageScopeAndName = try req.packageScopeAndName
        try req.checkAcceptHeader(expectedMediaType: .json)
        // We don't yet support "per_page" and "page" query
        // parameters on the GET /{scope}/{name} endpoint.
//        let queryParams = try req.query.decode(ListPackageReleasesQueryParameters.self)

        let owner = packageScopeAndName.scope.value
        let repo = packageScopeAndName.name.value

        // Sync the tags with the Github API and return the cached tags.
        // For this endpoint, we will always sync with the API.
        let tagFile = try await syncTags(owner: owner, repo: repo, forceSync: true)

        // The PersistenceClient.TagFile already has a [Version: String] map.
        // So we just need to send the keys to that map. Those are only
        // valid versions of the repository.
        return .init(versions: tagFile.versionToTagName.keys.sorted(by: >))
    }

    private struct ListPackageReleasesQueryParameters: Content {
        var perPage: Int?
        var page: Int?

        enum CodingKeys: String, CodingKey {
            case perPage = "per_page"
            case page
        }
    }
}

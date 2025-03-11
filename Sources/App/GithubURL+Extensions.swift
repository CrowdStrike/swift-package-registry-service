import APIUtilities
import GithubAPIClient

extension GithubURL {
    var asInput: GithubAPIClient.ListRepositoryTags.Input {
        .init(owner: scope, repo: name)
    }

    var packageIdentifier: String {
        PackageScopeAndName(scope: .init(value: scope), name: .init(value: name)).packageId
    }
}

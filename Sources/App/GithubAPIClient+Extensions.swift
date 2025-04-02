import APIUtilities
import GithubAPIClient
import Vapor

extension GithubAPIClient.ListRepositoryTags.Input {
    mutating func updatePageInfo(_ pageInfo: APIUtilities.PageInfo) {
        perPage = pageInfo.perPage
        page = pageInfo.page
    }
}

extension GithubAPIClient.ListRepositoryTags.Output {

    var nextPage: APIUtilities.PageInfo? {
        guard case .ok(let okBody) = self else {
            return nil
        }
        return APIUtilities.nextPage(forLinkHeader: okBody.linkHeader)
    }

    mutating func updateWithNextPage(_ pageOutput: Self) {
        switch (self, pageOutput) {
        case let (.ok(okBodySelf), .ok(okBodyPage)):
            self = .ok(
                .init(
                    // TODO: preserve non-pagination-related link headers
                    linkHeader: nil,
                    tags: okBodySelf.tags + okBodyPage.tags
                )
            )
        default:
            // If we are an error, then don't update
            break
        }
    }
}

extension GithubAPIClient.GetReleaseByTagName.Output {

    var isOK: Bool {
        switch self {
        case .ok:
            return true
        default:
            return false
        }
    }

    var zipBallURL: String? {
        switch self {
        case .ok(let okBody):
            return okBody.zipBallURL
        default:
            return nil
        }
    }
}

extension GithubAPIClient.GetContent.Output {
    var isOK: Bool {
        switch self {
        case .ok: true
        default: false
        }
    }

    func linkHeader(
        serverURL: String,
        owner: String,
        repo: String,
        version: String,
        swiftVersion: String?,
        manifests: [Manifest.FileName] = []
    ) -> String {
        manifests
            .filter { $0.swiftVersion != swiftVersion }
            .map {
                // TODO: support swift-tools-version
                "<\(serverURL)/\(owner)/\(repo)/\(version)/Package.swift\($0.queryArguments)>; rel=\"alternate\"; filename=\"\($0.fileName)\""
            }
            .joined(separator: ", ")
    }
}

import GithubAPIClient
import GithubOpenAPI
import OpenAPIRuntime

extension GithubAPIClient.ListRepositoryTags.Input {
    var asInput: Operations.ReposListTags.Input {
        .init(
            path: .init(owner: owner, repo: repo),
            query: .init(perPage: perPage, page: page),
            headers: .init(accept: [.init(contentType: .json)])
        )
    }
}

extension GithubAPIClient.GetLatestRelease.Input {
    var asInput: Operations.ReposGetLatestRelease.Input {
        .init(
            path: .init(owner: owner, repo: repo),
            headers: .init(accept: [.init(contentType: .json)])
        )
    }
}

extension GithubAPIClient.GetReleaseByTagName.Input {
    var asInput: Operations.ReposGetReleaseByTag.Input {
        .init(
            path: .init(owner: owner, repo: repo, tag: tag),
            headers: .init(accept: [.init(contentType: .json)])
        )
    }
}

extension GithubAPIClient.GetContent.Input {
    var asInput: Operations.ReposGetContent.Input {
        .init(
            path: .init(
                owner: owner,
                repo: repo,
                path: path.pathType
            ),
            query: .init(ref: ref),
            headers: .init(accept: [.init(contentType: .applicationVnd_github_objectJson)])
        )
    }
}

extension GithubAPIClient.GetContent.Input.PathType {
    var pathType: String {
        switch self {
        case .directory: ""
        case .file(let fileName): fileName
        }
    }
}

extension GithubAPIClient.GetRepository.Input {
    var asInput: Operations.ReposGet.Input {
        .init(
            path: .init(owner: owner, repo: repo),
            headers: .init(accept: [.init(contentType: .json)])
        )
    }
}

import Foundation
import GithubAPIClient
import GithubOpenAPI
import OpenAPIRuntime

extension Operations.ReposGetLatestRelease.Output {
    var asOutput: GithubAPIClient.GetLatestRelease.Output {
        switch self {
        case .ok(let okBody):
            .ok(okBody.body.release.asRelease)
        case .undocumented(let statusCode, _):
            .other(statusCode)
        }
    }
}

extension Operations.ReposGetLatestRelease.Output.Ok.Body {
    var release: Components.Schemas.Release {
        switch self {
        case .json(let release): return release
        }
    }
}

extension Components.Schemas.Release {

    var asRelease: GithubAPIClient.Release {
        .init(
            createdAt: createdAt,
            draft: draft,
            id: id,
            name: name,
            prerelease: prerelease,
            publishedAt: publishedAt,
            tagName: tagName,
            zipBallURL: zipballUrl
        )
    }
}

extension Operations.ReposListTags.Output {
    func toOutput(perPage: Int?, page: Int?) -> GithubAPIClient.ListRepositoryTags.Output {
        switch self {
        case .ok(let okBody):
            .ok(okBody.toOKBody(perPage: perPage, page: page))
        case .undocumented(let statusCode, _):
            .other(.init(status: .init(code: statusCode)))
        }
    }
}

extension Operations.ReposListTags.Output.Ok {
    func toOKBody(perPage: Int?, page: Int?) -> GithubAPIClient.ListRepositoryTags.OKBody {
        // Per https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-tags,
        // the default for "page" is 1 and the default for "per_page" is 30.
        // In the API definition, page is 1-based, not 0-based.
        let pageDefault = 1
        let perPageDefault = 30
        // Compute the 0-based page index
        let pageIndex = (page ?? pageDefault) - 1
        let pageSize = perPage ?? perPageDefault
        // Compute the 0-based offset for the first tag in the page
        let pageOffset = pageIndex * pageSize
        return .init(
            linkHeader: headers.link,
            tags: body.tags.enumerated().map { $1.toTag(apiLexicalOrder: pageOffset + $0) }
        )
    }
}

extension Operations.ReposListTags.Output.Ok.Body {
    var tags: [Components.Schemas.Tag] {
        switch self {
        case .json(let tags): return tags
        }
    }
}

extension Components.Schemas.Tag {
    func toTag(apiLexicalOrder: Int) -> GithubAPIClient.ListRepositoryTags.OKBody.Tag {
        .init(name: name, nodeId: nodeId, sha: commit.sha, zipBallURL: zipballUrl, apiLexicalOrder: apiLexicalOrder)
    }
}

extension Operations.ReposGetReleaseByTag.Output {
    var asOutput: GithubAPIClient.GetReleaseByTagName.Output {
        switch self {
        case .ok(let okBody):
             .ok(okBody.body.release.asRelease)
        case .notFound:
            .notFound
        case .undocumented(let statusCode, _):
            .other(.init(status: .init(code: statusCode)))
        }
    }
}

extension Operations.ReposGetReleaseByTag.Output.Ok.Body {
    var release: Components.Schemas.Release {
        switch self {
        case .json(let release): return release
        }
    }
}

extension Operations.ReposGetContent.Output {
    var asOutput: GithubAPIClient.GetContent.Output {
        switch self {
        case .ok(let okBody):
            return .ok(okBody.body.asOKBody)
        case .found:
            return .found
        case .notModified:
            return .notModified
        case .forbidden:
            return .forbidden
        case .notFound:
            return .notFound
        case .undocumented(let statusCode, _):
            return .other(.init(status: .init(code: statusCode)))
        }
    }
}

extension Operations.ReposGetContent.Output.Ok.Body {
    var asOKBody: GithubAPIClient.GetContent.OKBody {
        switch self {
        case .applicationVnd_github_objectJson(let objectJSONPayload):
            switch objectJSONPayload {
            case .dir(let contentTree):
                .directory(contentTree.asDirectory)
            case .file(let contentFile):
                .file(contentFile.asFile)
            case .submodule(let contentSubmodule):
                .submodule(contentSubmodule.asSubmodule)
            case .symlink(let contentSymlink):
                .symlink(contentSymlink.asSymlink)
            }
        case .json(let jsonPayload):
            switch jsonPayload {
            case .dir(let contentTree):
                .directory(contentTree.asDirectory)
            case .file(let contentFile):
                .file(contentFile.asFile)
            case .submodule(let contentSubmodule):
                .submodule(contentSubmodule.asSubmodule)
            case .symlink(let contentSymlink):
                .symlink(contentSymlink.asSymlink)
            }
        }
    }
}

extension Components.Schemas.ContentTree {
    var asDirectory: GithubAPIClient.GetContent.OKBody.Directory {
        .init(entries: entries.map { $0.map(\.asEntry) } ?? [])
    }
}

extension Components.Schemas.ContentTree.EntriesPayloadPayload {
    var asEntry: GithubAPIClient.GetContent.OKBody.Directory.Entry {
        .init(
            name: name,
            size: size,
            entryType: .init(rawValue: _type) ?? .file
        )
    }
}

extension Components.Schemas.ContentFile {
    var asFile: GithubAPIClient.GetContent.OKBody.File {
        .init(encoding: encoding, size: size, name: name, path: path, content: content)
    }
}

extension Components.Schemas.ContentSubmodule {
    var asSubmodule: GithubAPIClient.GetContent.OKBody.Submodule {
        .init(submoduleGitUrl: submoduleGitUrl, size: size, name: name, path: path, sha: sha, url: url)
    }
}

extension Components.Schemas.ContentSymlink {
    var asSymlink: GithubAPIClient.GetContent.OKBody.Symlink {
        .init(target: target, size: size, name: name, path: path, sha: sha, url: url)
    }
}

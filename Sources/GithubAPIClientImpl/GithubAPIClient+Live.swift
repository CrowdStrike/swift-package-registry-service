import ClientAuthMiddleware
import ClientLoggingMiddleware
import ClientStaticHeadersMiddleware
import Foundation
import GithubOpenAPI
import GithubAPIClient
import OpenAPIRuntime
import OpenAPIAsyncHTTPClient

extension GithubAPIClient {

    public static func live(
        clientTransport: ClientTransport = AsyncHTTPClientTransport(),
        githubAPIToken: String? = ProcessInfo.processInfo.environment["GITHUB_API_TOKEN"]
    ) -> Self {
        var middlewares: [ClientMiddleware] = [
            ClientStaticHeadersMiddleware(
                headers: [
                    .userAgent: "GithubAPIClient GithubOpenAPI/1.1.4 AsyncHTTPClientTransport/1.1.0"
                ]
            ),
            ClientLoggingMiddleware(bodyLoggingPolicy: .never),
        ]
        if let githubAPIToken {
            middlewares.insert(ClientAuthMiddleware(bearerToken: githubAPIToken), at: 0)
        }

        let client = GithubOpenAPI.Client(
            serverURL: Self.serverURL,
            transport: clientTransport,
            middlewares: middlewares
        )
        return Self(
            listRepositoryTags: {
                try await client.reposListTags($0.asInput).toOutput(perPage: $0.perPage, page: $0.page)
            },
            getLatestRelease: {
                try await client.reposGetLatestRelease($0.asInput).asOutput
            },
            getReleaseByTagName: {
                try await client.reposGetReleaseByTag($0.asInput).asOutput
            },
            getContent: {
                try await client.reposGetContent($0.asInput).asOutput
            },
            getRepository: {
                try await client.reposGet($0.asInput).asOutput
            }
        )
    }

    private static let serverURLString = "https://api.github.com"
    private static let serverURL: URL = {
        guard let url = URL(string: serverURLString) else {
            fatalError("Could not create URL for Github API")
        }
        return url
    }()
}

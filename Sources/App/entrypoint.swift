import ChecksumClient
import ChecksumClientImpl
import FileClient
import GithubAPIClient
import GithubAPIClientImpl
import HTTPStreamClient
import Logging
import Vapor

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = try await Application.make(env)

        let githubAPIToken = Environment.get("GITHUB_API_TOKEN") ?? ""
        let fileClient: FileClient = .live(
            nonBlockingFileIO: app.fileio,
            byteBufferAllocator: app.allocator
        )
        let httpStreamClient: HTTPStreamClient = .live()
        do {
            try await configure(
                app,
                environment: env,
                githubAPIClient: .live(),
                checksumClient: .live(httpStreamClient: httpStreamClient, fileClient: fileClient),
                httpStreamClient: httpStreamClient,
                persistenceClient: .live(
                    fileClient: fileClient,
                    httpStreamClient: httpStreamClient,
                    byteBufferAllocator: app.allocator,
                    cacheRootDirectory: app.directory.workingDirectory.appending(".sprsCache/"),
                    githubAPIToken: githubAPIToken
                ),
                logger: app.logger,
                githubAPIToken: githubAPIToken,
                clientSupportsPagination: Environment.get("CLIENT_SUPPORTS_PAGINATION").flatMap(Bool.init) ?? false
            )
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.execute()
        try await app.asyncShutdown()
    }
}

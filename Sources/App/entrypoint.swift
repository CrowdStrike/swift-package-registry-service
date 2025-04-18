import ChecksumClient
import ChecksumClientImpl
import Dependencies
import FileClient
import GithubAPIClient
import GithubAPIClientImpl
import HTTPStreamClient
import _NIOFileSystem
import Logging
import Vapor

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = try await Application.make(env)

        let githubAPIToken = Environment.get("GITHUB_API_TOKEN") ?? ""
        let fileClient: FileClient = .live()
        let httpStreamClient: HTTPStreamClient = .live()
        let cacheRootDirectory = app.directory.workingDirectory.appending(".sprsCache/")
        try await Self.ensureDirectoryExists(cacheRootDirectory)
        let manifestsCacheDirectory = cacheRootDirectory.appending("manifests/")
        try await Self.ensureDirectoryExists(manifestsCacheDirectory)
        let dbPath = cacheRootDirectory.appending("db.sqlite")
        @Dependency(\.uuid) var uuid
        do {
            try await configure(
                app,
                environment: env,
                cacheRootDirectory: cacheRootDirectory,
                githubAPIClient: .live(),
                checksumClient: .live(httpStreamClient: httpStreamClient, fileClient: fileClient),
                httpStreamClient: httpStreamClient,
                persistenceClient: .live(
                    fileClient: fileClient,
                    httpStreamClient: httpStreamClient,
                    byteBufferAllocator: app.allocator,
                    cacheRootDirectory: cacheRootDirectory,
                    githubAPIToken: githubAPIToken
                ),
                logger: app.logger,
                githubAPIToken: githubAPIToken,
                sqliteConfiguration: .file(dbPath),
                uuidGenerator: uuid,
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

    private static func ensureDirectoryExists(_ path: String) async throws {
        // Ensure the cache directory exists
        do {
            try await FileSystem.shared.createDirectory(
                at: FilePath(path),
                withIntermediateDirectories: true,
                permissions: [.ownerReadWriteExecute, .groupReadExecute, .otherReadExecute]
            )
        } catch let fileSystemError as FileSystemError {
            switch fileSystemError.code {
            case .fileAlreadyExists:
                return
            default:
                throw fileSystemError
            }
        } catch {
            throw error
        }
    }
}

import ChecksumClient
import Fluent
import FluentSQLiteDriver
import GithubAPIClient
import HTTPStreamClient
import PersistenceClient
import Vapor

public func configure(
    _ app: Application,
    environment: Environment,
    githubAPIClient: GithubAPIClient,
    checksumClient: ChecksumClient,
    httpStreamClient: HTTPStreamClient,
    persistenceClient: PersistenceClient,
    logger: Logger,
    githubAPIToken: String,
    sqliteConfiguration: SQLiteConfiguration,
    clientSupportsPagination: Bool = false
) async throws {
    // Clear all default middleware (then, add back route logging)
    app.middleware = .init()
    app.middleware.use(CustomRouteLoggingMiddleware(logLevel: .info))
    // Add custom error handling middleware first.
    app.middleware.use(ProblemDetailsErrorMiddleware.default(environment: environment))

    // Set up the database
    app.databases.use(.sqlite(sqliteConfiguration), as: .sqlite)
    // Add migrations
    app.migrations.add(CreateRepositories())
    if sqliteConfiguration.storage.isMemory {
        try await app.autoMigrate()
    }

    let scheme = app.http.server.configuration.tlsConfiguration != nil ? "https" : "http"
    let hostname = app.http.server.configuration.hostname
    let port = app.http.server.configuration.port
    let serverURLString = "\(scheme)://\(hostname):\(port)"

    let controller = PackageRegistryController(
        serverURLString: serverURLString,
        clientSupportsPagination: clientSupportsPagination,
        githubAPIToken: githubAPIToken,
        githubAPIClient: githubAPIClient,
        checksumClient: checksumClient,
        httpStreamClient: httpStreamClient,
        persistenceClient: persistenceClient,
        appLogger: logger
    )

    try app.register(collection: controller)
}

extension SQLiteConfiguration.Storage {
    var isMemory: Bool {
        switch self {
        case .file: false
        case .memory: true
        }
    }
}

import ChecksumClient
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
    clientSupportsPagination: Bool = false
) async throws {
    // Clear all default middleware (then, add back route logging)
    app.middleware = .init()
    app.middleware.use(CustomRouteLoggingMiddleware(logLevel: .info))
    // Add custom error handling middleware first.
    app.middleware.use(ProblemDetailsErrorMiddleware.default(environment: environment))

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

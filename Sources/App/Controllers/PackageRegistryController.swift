import Dependencies
import ChecksumClient
import GithubAPIClient
import HTTPStreamClient
import PersistenceClient
import Vapor

struct PackageRegistryController: RouteCollection {
    let serverURLString: String
    let clientSupportsPagination: Bool
    let githubAPIToken: String
    let githubAPIClient: GithubAPIClient
    let checksumClient: ChecksumClient
    let httpStreamClient: HTTPStreamClient
    let persistenceClient: PersistenceClient
    let logger = Logger(label: "PackageRegistryController")

    func boot(routes: any RoutesBuilder) throws {
        let scopeName = routes.grouped(":scope", ":name")

        // List Package Releases
        scopeName.get(use: listPackageReleases)

        scopeName.group(":version") { scopeNameVersion in
            // Fetch Release Metadata or Download source archive
            scopeNameVersion.get(use: fetchReleaseMetadataOrDownloadSourceArchive)
            // Create Package Release
            scopeNameVersion.put(use: createPackageRelease)
            // Fetch Manifest
            scopeNameVersion.get("Package.swift", use: fetchManifest)
        }

        // Lookup Package Identifiers
        routes.get("identifiers", use: lookupPackageIdentifiers)

        // Login
        routes.post("login", use: login)
    }
}

import Foundation
import PersistenceClient
import Vapor

actor IdentifiersActor {
    struct PackageIDLoaderOutput: Equatable, Sendable, Codable {
        var packageID: String
        var otherURLs: [String]

        init(packageID: String, otherURLs: [String]) {
            self.packageID = packageID
            self.otherURLs = otherURLs
        }
    }

    typealias PackageIDLoader = @Sendable (_ url: String, _ logger: Logger) async throws -> PackageIDLoaderOutput?

    private var memoryCache: [String: PackageIDState] = [:]
    private let packageIDLoader: PackageIDLoader

    init(packageIDLoader: @escaping PackageIDLoader) {
        self.packageIDLoader = packageIDLoader
    }

    func load(from persistenceClient: PersistenceClient) async throws {
        // Only load when the memory cache is empty
        guard memoryCache.isEmpty else { return }
        let repositoriesFile = try await persistenceClient.readRepositories()
        memoryCache = repositoriesFile.urlToPackageIDMap.mapValues { .loaded($0) }
    }

    func loadPackageID(url: String, logger: Logger) async throws -> String? {
        if let state = memoryCache[url] {
            switch state {
            case .loaded(let packageID):
                logger.debug("Loaded packageId \"\(packageID)\" from memory cache for \"\(url)\"")
                return packageID
            case .loading(let task):
                logger.debug("PackageID memory cache is loading for \"\(url)\". Awaiting loading task.")
                return try await task.value?.packageID
            }
        }

        let task = Task {
            try await packageIDLoader(url, logger)
        }

        memoryCache[url] = .loading(task)

        do {
            if let output = try await task.value {
                logger.debug("Loaded packageID=\"\(output.packageID)\" from packageIDLoader for \"\(url)\"")
                memoryCache[url] = .loaded(output.packageID)
                output.otherURLs.forEach {
                    if memoryCache[$0] == nil {
                        memoryCache[$0] = .loaded(output.packageID)
                    }
                }
                return output.packageID
            } else {
                logger.debug("packageIDLoader returned nil output for \"\(url)\"")
                memoryCache[url] = nil
                return nil
            }
        } catch {
            memoryCache[url] = nil
            logger.error("packageIDLoader threw an error for \"\(url)\": \(error)")
            throw error
        }
    }

    private enum PackageIDState {
        case loading(Task<PackageIDLoaderOutput?, Error>)
        case loaded(String)
    }
}

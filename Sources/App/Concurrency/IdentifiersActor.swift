import Foundation
import PersistenceClient
import Vapor

actor IdentifiersActor {
    typealias PackageIDLoader = @Sendable (_ url: String, _ logger: Logger) async throws -> String?

    private var memoryCache: [String: PackageIDState] = [:]
    private let packageIDLoader: PackageIDLoader

    init(packageIDLoader: @escaping PackageIDLoader) {
        self.packageIDLoader = packageIDLoader
    }

    func load(from persistenceClient: PersistenceClient) async throws {
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
                return try await task.value
            }
        }

        let task = Task {
            try await packageIDLoader(url, logger)
        }

        memoryCache[url] = .loading(task)

        do {
            if let packageID = try await task.value {
                logger.debug("Loaded packageID=\"\(packageID)\" from packageIDLoader for \"\(url)\"")
                memoryCache[url] = .loaded(packageID)
                return packageID
            } else {
                logger.debug("packageIDLoader returned nil packageID for \"\(url)\"")
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
        case loading(Task<String?, Error>)
        case loaded(String)
    }
}

import APIUtilities
import Fluent
import Foundation
import Vapor

actor IdentifiersActor {
    typealias PackageIDLoader = @Sendable (_ githubURL: GithubURL, _ logger: Logger, _ database: any Database) async throws -> String?

    private var memoryCache: [String: PackageIDState] = [:]
    private let packageIDLoader: PackageIDLoader

    init(packageIDLoader: @escaping PackageIDLoader) {
        self.packageIDLoader = packageIDLoader
    }

    func loadPackageID(githubURL: GithubURL, logger: Logger, database: any Database) async throws -> String? {
        let memoryCacheKey = githubURL.cacheKey
        if let state = memoryCache[memoryCacheKey] {
            switch state {
            case .loaded(let packageID):
                logger.debug("Loaded packageId \"\(packageID)\" from memory cache for \"\(githubURL)\"")
                return packageID
            case .loading(let task):
                logger.debug("PackageID memory cache is loading for \"\(githubURL)\". Awaiting loading task.")
                return try await task.value
            }
        }

        let task = Task {
            try await packageIDLoader(githubURL, logger, database)
        }

        memoryCache[memoryCacheKey] = .loading(task)

        do {
            if let packageID = try await task.value {
                logger.debug("Loaded packageID=\"\(packageID)\" from packageIDLoader for \"\(githubURL)\"")
                memoryCache[memoryCacheKey] = .loaded(packageID)
                return packageID
            } else {
                logger.debug("packageIDLoader returned nil output for \"\(githubURL)\"")
                memoryCache[memoryCacheKey] = nil
                return nil
            }
        } catch {
            memoryCache[memoryCacheKey] = nil
            logger.error("packageIDLoader threw an error for \"\(githubURL)\": \(error)")
            throw error
        }
    }

    private enum PackageIDState {
        case loading(Task<String?, Error>)
        case loaded(String)
    }
}

private extension GithubURL {

    var cacheKey: String {
        "\(scope.lowercased()).\(name.lowercased())"
    }
}

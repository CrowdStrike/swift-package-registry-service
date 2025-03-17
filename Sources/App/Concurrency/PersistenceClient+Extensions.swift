import PersistenceClient

extension PersistenceClient.RepositoriesFile {

    var urlToPackageIDMap: [String: String] {
        repositories
            .reduce(into: [String: String]()) { partialResult, repository in
                let packageID = repository.packageID
                partialResult[repository.cloneURL] = packageID
                partialResult[repository.sshURL] = packageID
                partialResult[repository.htmlURL] = packageID
            }
    }
}

extension PersistenceClient.Repository {

    var packageID: String {
        "\(owner.lowercased()).\(name.lowercased())"
    }
}

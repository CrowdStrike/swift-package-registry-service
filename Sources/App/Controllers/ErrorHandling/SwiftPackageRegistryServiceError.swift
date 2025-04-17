enum SwiftPackageRegistryServiceError: Error {
    case manifestHasNoSwiftToolsVersion(owner: String, repo: String, version: String, swiftVersion: String?)
}

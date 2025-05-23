import Foundation
import DependenciesMacros

@DependencyClient
public struct ChecksumClient: Sendable {
    public var createChecksum: @Sendable () -> HashAlgorithm = {
        reportIssue("\(Self.self).createChecksum not implemented")
        return HashAlgorithmFactory.mock()
    }
}

extension ChecksumClient {
    public static let mock = Self()
}

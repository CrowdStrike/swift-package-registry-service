extension ChecksumClient {

    public enum ComputeChecksum {
        public struct Input: Equatable, Sendable {
            public var urlString: String
            public var apiToken: String

            public init(urlString: String, apiToken: String) {
                self.urlString = urlString
                self.apiToken = apiToken
            }
        }

        public enum Output: Equatable, Sendable {
            case ok(OKBody)
            case httpError(Int)
        }

        public struct OKBody: Equatable, Sendable {
            public var checksum: String
            
            public init(checksum: String) {
                self.checksum = checksum
            }
        }
    }
}

extension ChecksumClient.ComputeChecksum.Input {
    public static let mock = Self(
        urlString: "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.5.0",
        apiToken: ""
    )
}

extension ChecksumClient.ComputeChecksum.Output {
    public static let mock: Self = .ok(.init(checksum: "06bc2e1e4f22b40bc2c4c045d7559bcceb94e684cd32ebb295eee615890d724e"))

    public var isOK: Bool {
        switch self {
        case .ok: true
        default: false
        }
    }

    public var checksum: String? {
        switch self {
        case .ok(let okBody): return okBody.checksum
        case .httpError: return nil
        }
    }
}

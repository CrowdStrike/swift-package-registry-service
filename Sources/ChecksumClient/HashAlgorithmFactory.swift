enum HashAlgorithmFactory {

    public static func live() -> HashAlgorithm {
        #if canImport(CryptoKit)
        if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) {
            return CryptoKitSHA256()
        } else {
            return InternalSHA256()
        }
        #else
        return InternalSHA256()
        #endif
    }

    public static func test(result: [UInt8]) -> HashAlgorithm {
        TestHash(result: result)
    }

    public static func mock() -> HashAlgorithm { test(result: []) }

    struct TestHash: HashAlgorithm {
        let result: [UInt8]

        public mutating func hash(_ bytes: [UInt8]) { }

        public func finalize() -> [UInt8] { result }
    }
}

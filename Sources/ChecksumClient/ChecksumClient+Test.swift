import Overture

extension ChecksumClient {

    public static func test(
        createChecksumResult: [UInt8]? = nil
    ) -> Self {
        update(.mock) {
            if let createChecksumResult {
                $0.createChecksum = { HashAlgorithmFactory.test(result: createChecksumResult) }
            }
        }
    }
}

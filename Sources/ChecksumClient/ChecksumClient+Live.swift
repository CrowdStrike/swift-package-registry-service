extension ChecksumClient {

    public static func live() -> Self {
        Self(
            createChecksum: HashAlgorithmFactory.live
        )
    }
}

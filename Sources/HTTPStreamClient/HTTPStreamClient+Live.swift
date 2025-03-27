import AsyncHTTPClient

extension HTTPStreamClient {
    public static func live(
        httpClient: HTTPClient = .shared
    ) -> Self {
        Self(
            execute: {
                try await httpClient.execute($0, timeout: .seconds(30))
            }
        )
    }
}

import AsyncHTTPClient

extension HTTPStreamClient {
    public static func test(
        response: HTTPClientResponse = .mock
    ) -> Self {
        Self(
            execute: { _ in response }
        )
    }
}

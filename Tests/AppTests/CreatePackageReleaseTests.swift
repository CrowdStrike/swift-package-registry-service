@testable import App
import ConcurrencyExtras
import GithubAPIClient
import ChecksumClient
import HTTPStreamClient
import Testing
import VaporTesting

@Suite("creatPackageRelease Tests")
struct CreatePackageReleaseTests {

    @Test func anyRequestResultsInMethodNotAllowed() async throws {
        try await testApp { app in
            try await app.testing().test(.PUT, "pointfreeco/swift-clocks/0.6.0") { res in
                #expect(res.status == .methodNotAllowed)
            }
        }
    }
}

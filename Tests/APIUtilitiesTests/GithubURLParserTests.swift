@testable import APIUtilities
import Testing

struct GithubURLParserTests {

    @Test func githubURLParsing() {
        struct TestCase {
            let urlString: String
            let expectedGithubURL: GithubURL?

            init(_ urlString: String, _ expectedGithubURL: GithubURL?) {
                self.urlString = urlString
                self.expectedGithubURL = expectedGithubURL
            }
        }
        let testCases: [TestCase] = [
            .init(
                "https://github.com/pointfreeco/swift-overture.git",
                .init(scope: "pointfreeco", name: "swift-overture", urlType: .clone)
            ),
            .init(
                "git@github.com:pointfreeco/swift-overture.git",
                .init(scope: "pointfreeco", name: "swift-overture", urlType: .ssh)
            ),
            .init(
                "https://github.com/pointfreeco/swift-overture",
                .init(scope: "pointfreeco", name: "swift-overture", urlType: .html)
            ),
            .init(
                "https://github.com/pointfreeco/swift-overture/Package.swift",
                nil
            ),
            .init(
                "http://github.com/pointfreeco/swift-overture.git",
                nil
            ),
            .init(
                "https://subdomain.github.com/pointfreeco/swift-overture.git",
                nil
            ),
        ]

        let parser = GithubURLParser()
        testCases.forEach { testCase in
            let actualGithubURL = parser.parse(urlString: testCase.urlString)
            #expect(
                actualGithubURL == testCase.expectedGithubURL,
                "Expected parsed GithubURL to be \(String(describing: testCase.expectedGithubURL)), but it was \(String(describing: actualGithubURL))."
            )
        }
    }
}

@testable import APIUtilities
import Testing

struct SwiftToolsVersionParserTests {

    @Test func swiftToolsVersionParsing() throws {
        struct TestCase {
            var manifest: String
            var swiftToolsVersion: String?

            init(_ manifest: String, _ swiftToolsVersion: String?) {
                self.manifest = manifest
                self.swiftToolsVersion = swiftToolsVersion
            }
        }
        let testCases: [TestCase] = [
            // Valid major and minor
            .init(
                """
                // swift-tools-version: 5.9

                import PackageDescription

                let package = Package(
                )
                """,
                "5.9"
            ),
            // Valid major and minor, no whitespace before version
            .init(
                """
                // swift-tools-version:5.9

                import PackageDescription

                let package = Package(
                )
                """,
                "5.9"
            ),
            // Valid full semantic version (including prerelease and build)
            .init(
                """
                // swift-tools-version: 1.0.0-beta+exp.sha.5114f85

                import PackageDescription

                let package = Package(
                )
                """,
                "1.0.0-beta+exp.sha.5114f85"
            ),
            // Valid full semantic version (including prerelease and build), with optional ; at end
            .init(
                """
                // swift-tools-version: 1.0.0-beta+exp.sha.5114f85;

                import PackageDescription

                let package = Package(
                )
                """,
                "1.0.0-beta+exp.sha.5114f85"
            ),
            // Valid - two spaces between comment and swift-tools-version
            .init(
                """
                //  swift-tools-version: 6.0

                import PackageDescription

                let package = Package(
                )
                """,
                "6.0"
            ),
            // Valid - no spaces between comment and swift-tools-version
            .init(
                """
                //swift-tools-version: 6.0

                import PackageDescription

                let package = Package(
                )
                """,
                "6.0"
            ),
            // Invalid - blank line before swift-tools-version
            .init(
                """
                
                // swift-tools-version: 6.0

                import PackageDescription

                let package = Package(
                )
                """,
                nil
            ),
            // Invalid - space before swift-tools-version comment
            .init(
                """
                 // swift-tools-version: 6.0

                import PackageDescription

                let package = Package(
                )
                """,
                nil
            ),
        ]

        let parser = SwiftToolsVersionParser()
        try testCases.forEach {
            let swiftToolsVersion = try parser.parse($0.manifest)
            #expect(
                swiftToolsVersion == $0.swiftToolsVersion,
                "Expected swiftToolsVersion to be \(String(describing: $0.swiftToolsVersion)), but it was \(String(describing: swiftToolsVersion))"
            )
        }
    }
}

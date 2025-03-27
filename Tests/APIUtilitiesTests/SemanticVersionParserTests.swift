@testable import APIUtilities
import Testing

struct SemanticVersionParserTests {

    @Test func wholeStringSemanticVersionParsing() throws {
        struct TestCase {
            var tag: String
            var semVer: SemanticVersion?

            init(_ tag: String, _ semVer: SemanticVersion?) {
                self.tag = tag
                self.semVer = semVer
            }
        }
        let testCases: [TestCase] = [
            // Valid
            .init("1.2.3", .init(1, 2, 3)),
            // Leading zeros not allowed in major
            .init("01.2.3", nil),
            // Leading zeros not allowed in minor
            .init("1.02.3", nil),
            // Leading zeros not allowed in patch
            .init("1.2.03", nil),
            // Valid prerelease information
            .init("1.2.3-alpha.beta.gamma", .init(1, 2, 3, prerelease: ["alpha", "beta", "gamma"])),
            // Pre-release identifiers are [0-9a-zA-Z-]
            .init("1.2.3-alpha.be$ta.gamma", nil),
            // Pre-release identifiers cannot be empty
            .init("1.2.3-alpha..gamma", nil),
            // Numeric identifiers cannot have leading zeros
            .init("1.2.3-alpha.011.gamma", nil),
            // Examples from: https://semver.org/#spec-item-9
            .init("1.0.0-alpha", .init(1, 0, 0, prerelease: ["alpha"])),
            .init("1.0.0-alpha.1", .init(1, 0, 0, prerelease: ["alpha", "1"])),
            .init("1.0.0-0.3.7", .init(1, 0, 0, prerelease: ["0", "3", "7"])),
            .init("1.0.0-x.7.z.92", .init(1, 0, 0, prerelease: ["x", "7", "z", "92"])),
            .init("1.0.0-x-y-z.--", .init(1, 0, 0, prerelease: ["x-y-z", "--"])),
            // Examples from https://semver.org/#spec-item-10
            .init("1.0.0-alpha+001", .init(1, 0, 0, prerelease: ["alpha"], metadata: ["001"])),
            .init("1.0.0+20130313144700", .init(1, 0, 0, metadata: ["20130313144700"])),
            .init("1.0.0-beta+exp.sha.5114f85", .init(1, 0, 0, prerelease: ["beta"], metadata: ["exp", "sha", "5114f85"])),
            .init("1.0.0+21AF26D3----117B344092BD", .init(1, 0, 0, metadata: ["21AF26D3----117B344092BD"])),
        ]

        let parser = SemanticVersionParser()
        try testCases.forEach {
            let semVer = try parser.parse($0.tag)
            #expect(
                semVer == $0.semVer,
                "Expected \"\($0.tag)\" to be \(String(describing: $0.semVer)), but it was \(String(describing: semVer))"
            )
        }
    }

    @Test func semanticVersionRangeParsing() throws {
        struct TestCase {
            var tag: String
            var semVer: String?

            init(_ tag: String, _ semVer: String?) {
                self.tag = tag
                self.semVer = semVer
            }
        }
        let testCases: [TestCase] = [
            // Whole string is valid Semantic Version
            .init("1.2.3", "1.2.3"),
            // Valid semantic version with prefixes
            .init("v1.2.3", "1.2.3"),
            .init("ver1.2.3", "1.2.3"),
            // Valid semantic version with suffixes
            .init("1.2.3tag", "1.2.3"),
            .init("1.2.3version", "1.2.3"),
            .init("1.2.3$", "1.2.3"),
            // Valid semantic version with prefixes and suffixes
            .init("v1.2.3 beta", "1.2.3"),
            .init("ver1.2.3_prereleasebeta", "1.2.3"),
            // No valid semantic version anywhere in the string
            .init("v1.2", nil),
            .init("v1.2-alpha", nil),
        ]

        let parser = SemanticVersionParser()
        try testCases.forEach {
            let semVer = try parser.semVerString(from: $0.tag)
            #expect(
                semVer == $0.semVer,
                "Expected \($0.tag) to have valid SemVer substring \(String(describing: $0.semVer)), but instead the parser produced \(String(describing: semVer))"
            )
        }
    }
}

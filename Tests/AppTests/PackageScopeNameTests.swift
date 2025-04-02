import Testing
@testable import App

@Suite("Package Scope and Package Name Tests")
struct PackageScopeTests {

    @Test func packageScopes() throws {
        struct TestCase {
            let scope: String
            let expected: Bool

            init(_ scope: String, _ expected: Bool) {
                self.scope = scope
                self.expected = expected
            }
        }

        let testCases: [TestCase] = [
            // 39 characters - the maximum length
            .init("123456789012345678901234567890123456789", true),
            // 40 characters - 1 character over the maximum
            .init("1234567890123456789012345678901234567890", false),
            // Hyphen at the beginning - invalid
            .init("-aaaaaaaaaaaaaaaaaaa", false),
            // Hyphen at the end - invalid
            .init("aaaaaaaaaaaaaaaaaaa-", false),
            // Two consecutive hypens - invalid
            .init("aaaaaaaaa--aaaaaaaaa", false),
            // Lots of hypens, but not at the beginning or end, and none consecutively
            .init("a-a-a-a-a-a-a-a-a-a-a", true),
        ]

        for testCase in testCases {
            let actual = PackageScope(value: testCase.scope).isValid
            #expect(testCase.expected == actual)
        }
    }

    @Test func packageNames() throws {
        struct TestCase {
            let name: String
            let expected: Bool

            init(_ name: String, _ expected: Bool) {
                self.name = name
                self.expected = expected
            }
        }

        let testCases: [TestCase] = [
            // 100 characters - valid
            .init("1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890", true),
            // 101 characters - invalid
            .init("12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901", false),
            // Only alphanumeric, underscores, and hyphens - valid
            .init("abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ-0123456789", true),
            // Includes a $ (some other character than alphanumeric, underscores, and hyphens) - invalid
            .init("abcdefghijklmnopqrstuvwxyz_$ABCDEFGHIJKLMNOPQRSTUVWXYZ-0123456789", false),
            // Underscore at the beginning - invalid
            .init("_abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ-0123456789", false),
            // Underscore at the end - invalid
            .init("abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ-0123456789_", false),
            // Hyphen at the beginning - invalid
            .init("-abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ-0123456789", false),
            // Hyphen at the end - invalid
            .init("abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ-0123456789-", false),
            // Two consecutive underscores - invalid
            .init("abcdefghijklmnopqrstuvwxyz__ABCDEFGHIJKLMNOPQRSTUVWXYZ-0123456789", false),
            // Two consecutive hyphens - invalid
            .init("abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ--0123456789", false),
            // Underscore followed by hyphen - invalid
            .init("abcdefghijklmnopqrstuvwxyz_-ABCDEFGHIJKLMNOPQRSTUVWXYZ--0123456789", false),
            // Hyphen followed by underscore - invalid
            .init("abcdefghijklmnopqrstuvwxyz-_ABCDEFGHIJKLMNOPQRSTUVWXYZ--0123456789", false),
        ]

        for testCase in testCases {
            let actual = PackageName(value: testCase.name).isValid
            #expect(testCase.expected == actual, "Expected \"\(testCase.name)\" to be \(testCase.expected), but it was not.")
        }
    }
}

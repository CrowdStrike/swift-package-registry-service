import Testing
@testable import APIUtilities

@Suite("ManifestFileName Tests")
struct ManifestFileNameTests {

    @Test func manifestFileNames() throws {
        struct TestCase {
            let fileName: String
            let expected: APIUtilities.Manifest.FileName?
        }

        let testCases: [TestCase] = [
            .init(fileName: "ClearlyNotAManifestFile", expected: nil),
            .init(fileName: "SomeSwiftFile.swift", expected: nil),
            .init(fileName: "Package.swift", expected: .unversioned),
            .init(fileName: "Package@swift-6.swift", expected: .versioned("6")),
            .init(fileName: "Package@swift-6..swift", expected: nil),
            .init(fileName: "Package@swift-6.0.swift", expected: .versioned("6.0")),
            .init(fileName: "Package@swift-6.0a.swift", expected: nil),
            .init(fileName: "Package@swift-6.0.4.swift", expected: .versioned("6.0.4")),
        ]

        let actualResults = try APIUtilities.Manifest.fileNames(from: testCases.map(\.fileName))
        #expect(actualResults == testCases.compactMap(\.expected))
    }
}

@testable import FileClient
import _NIOFileSystem
import Testing

struct FileClientTests {

    @Test func filePath() async throws {
        let filePath = FilePath("/Users/ehyche/src/bitbucket/crowdstrike/swift-package-registry-service-github/.sprsCache/pointfreeco/swift-overture/releases.json")
        let components = filePath.components
        var index = components.startIndex
        while index != components.endIndex {
            let ithComponent = components[index]
            print("components[index] = \(ithComponent)")
            index = components.index(after: index)
        }
    }
}

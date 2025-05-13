import APIUtilities
import FileClient
import Overture

extension PersistenceClient {

    public static func test(
        readTags: (@Sendable (_ owner: String, _ repo: String) async throws -> TagFile)? = nil,
        saveTags: (@Sendable (_ owner: String, _ repo: String, _ tagFile: TagFile) async throws -> Void)? = nil
    ) -> Self {
        update(.mock) {
            if let readTags {
                $0.readTags = readTags
            }
            if let saveTags {
                $0.saveTags = saveTags
            }
        }
    }
}

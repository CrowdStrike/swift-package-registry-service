import APIUtilities
import FileClient
import Overture

extension PersistenceClient {

    public static func test(
        readTags: (@Sendable (_ owner: String, _ repo: String) async throws -> TagFile)? = nil,
        saveTags: (@Sendable (_ owner: String, _ repo: String, _ tagFile: TagFile) async throws -> Void)? = nil,
        readSourceArchive: (@Sendable (_ owner: String, _ repo: String, _ version: Version) async throws -> SourceArchive?)? = nil,
        saveSourceArchive: (@Sendable(_ owner: String, _ repo: String, _ version: Version, _ zipBallURL: String) async throws -> String)? = nil,
        readReleaseMetadata: (@Sendable (_ owner: String, _ repo: String, _ version: Version) async throws -> ReleaseMetadata?)? = nil,
        saveReleaseMetadata: (@Sendable (_ owner: String, _ repo: String, _ metadata: ReleaseMetadata) async throws -> Void)? = nil,
        readManifests: (@Sendable (_ owner: String, _ repo: String, _ version: Version) async throws -> [Manifest])? = nil,
        saveManifests: (@Sendable (_ owner: String, _ repo: String, _ version: Version, _ manifests: [Manifest]) async throws -> [Manifest])? = nil
    ) -> Self {
        update(.mock) {
            if let readTags {
                $0.readTags = readTags
            }
            if let saveTags {
                $0.saveTags = saveTags
            }
            if let readSourceArchive {
                $0.readSourceArchive = readSourceArchive
            }
            if let saveSourceArchive {
                $0.saveSourceArchive = saveSourceArchive
            }
            if let readReleaseMetadata {
                $0.readReleaseMetadata = readReleaseMetadata
            }
            if let saveReleaseMetadata {
                $0.saveReleaseMetadata = saveReleaseMetadata
            }
            if let readManifests {
                $0.readManifests = readManifests
            }
            if let saveManifests {
                $0.saveManifests = saveManifests
            }
        }
    }
}

import Vapor

extension PackageRegistryController {

    func fetchReleaseMetadataOrDownloadSourceArchive(req: Request) async throws -> ReleaseMetadataOrSourceArchive {
        let packageVersion = try req.packageVersion
        if packageVersion.isZip {
            return .sourceArchive(try await downloadSourceArchive(req: req))
        } else {
            return .fetchReleaseMetadata(try await fetchReleaseMetadata(req: req))
        }
    }
}

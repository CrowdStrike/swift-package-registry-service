import Vapor

enum ReleaseMetadataOrSourceArchive {
    case fetchReleaseMetadata(FetchReleaseMetadata)
    case sourceArchive(SourceArchive)
}

extension ReleaseMetadataOrSourceArchive: AsyncResponseEncodable {

    func encodeResponse(for request: Request) async throws -> Response {
        switch self {
        case .fetchReleaseMetadata(let fetchReleaseMetadata):
            try await fetchReleaseMetadata.encodeResponse(for: request)
        case .sourceArchive(let sourceArchive):
            try await sourceArchive.encodeResponse(for: request)

        }
    }
}

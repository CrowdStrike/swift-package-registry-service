import HTTPTypes
import Vapor

extension HTTPResponse {
    var asListPackageReleases: ListPackageReleases {
        get throws {
            switch status {
            case .ok: .init(releases: [:])
            default: throw Abort(.init(statusCode: status.code))
            }
        }
    }
}

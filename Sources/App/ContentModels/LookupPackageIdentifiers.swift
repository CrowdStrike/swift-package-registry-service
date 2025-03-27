import APIUtilities
import Vapor

struct LookupPackageIdentifiers: Content {
    var identifiers: [String]
}

extension LookupPackageIdentifiers: AsyncResponseEncodable {

    func encodeResponse(for request: Request) async throws -> Response {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/json")
        headers.add(name: .contentVersion, value: SwiftRegistryAcceptHeader.Version.v1.rawValue)
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .default
        let data = try jsonEncoder.encode(self)
        return .init(status: .ok, headers: headers, body: .init(data: data))
    }
}

extension LookupPackageIdentifiers {
    static let mock = Self(
        identifiers: [
            "pointfreeco.swift-overture"
        ]
    )
}

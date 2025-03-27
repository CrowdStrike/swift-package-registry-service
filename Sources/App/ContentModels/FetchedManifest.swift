import APIUtilities
import Vapor

struct FetchedManifest: Equatable, Sendable {
    let response: ResponseType

    enum ResponseType: Equatable, Sendable {
        case ok(OKInfo)
        case seeOther
    }

    struct OKInfo: Equatable, Sendable {
        var allManifestFiles: [Manifest.File]
        var fileName: String
        var value: String
    }
}

extension FetchedManifest.OKInfo {

    var contentDispositionHeaderValue: String {
        "attachment; filename=\"\(fileName)\""
    }

    func linkHeaderValue(for request: Request) throws -> String {
        try allManifestFiles
            .filter { $0.fileName.fileName != fileName }
            .map { try $0.linkHeaderValue(for: request) }
            .joined(separator: ", ")
    }
}

extension Manifest.File {

    func linkHeaderValue(for request: Request) throws -> String {
        var components = [String]()
        components.append("<\(try request.fetchPackageMetadataURL)/Package.swift\(fileName.queryArguments)>")
        components.append("rel=\"alternate\"")
        components.append("filename=\"\(fileName.fileName)\"")
        if let swiftToolsVersion {
            components.append("swift-tools-version=\"\(swiftToolsVersion)\"")
        }
        return components.joined(separator: "; ")
    }
}

extension FetchedManifest: AsyncResponseEncodable {
    func encodeResponse(for request: Request) async throws -> Response {
        var headers = HTTPHeaders()
        switch response {
        case .ok(let okInfo):
            headers.add(name: .contentType, value: "text/x-swift")
            headers.add(name: .contentVersion, value: SwiftRegistryAcceptHeader.Version.v1.rawValue)
            headers.add(name: .contentDisposition, value: okInfo.contentDispositionHeaderValue)
            let linkHeaderValue = try okInfo.linkHeaderValue(for: request)
            if !linkHeaderValue.isEmpty {
                headers.add(name: .link, value: linkHeaderValue)
            }
            return .init(status: .ok, headers: headers, body: .init(string: okInfo.value))
        case .seeOther:
            headers.add(name: .location, value: try request.unversionedManifestURL)
            return .init(status: .seeOther, headers: headers)
        }
    }
}

extension FetchedManifest {
    static let mock = Self(
        response: .ok(
            .init(
                allManifestFiles: [],
                fileName: "Package.swift",
                value: """
                // swift-tools-version:5.0
                import Foundation
                import PackageDescription

                let package = Package(
                  name: "Overture",
                  products: [
                    .library(
                      name: "Overture",
                      targets: ["Overture"]),
                  ],
                  targets: [
                    .target(
                      name: "Overture",
                      dependencies: []),
                    .testTarget(
                      name: "OvertureTests",
                      dependencies: ["Overture"]),
                  ]
                )

                if ProcessInfo.processInfo.environment.keys.contains("PF_DEVELOP") {
                  package.dependencies.append(
                    contentsOf: [
                      .package(url: "https://github.com/yonaskolb/XcodeGen.git", from: "2.3.0"),
                    ]
                  )
                }
                """
            )
        )
    )
}

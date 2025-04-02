import APIUtilities
import Vapor

extension Request {
    var serverURL: String { application.serverURL }

    var packageScope: PackageScope {
        get throws {
            guard let packageScope = parameters.get("scope", as: PackageScope.self), packageScope.isValid else {
                throw Abort(.badRequest, title: "Package scope is invalid.")
            }
            return packageScope
        }
    }

    var packageName: PackageName {
        get throws {
            guard let packageName = parameters.get("name", as: PackageName.self), packageName.isValid else {
                throw Abort(.badRequest, title: "Package name is invalid.")
            }
            return packageName
        }
    }

    var packageScopeAndName: PackageScopeAndName {
        get throws {
            return .init(scope: try packageScope, name: try packageName)
        }
    }

    var packageVersion: PackageVersion {
        get throws {
            guard let version = parameters.get("version", as: PackageVersion.self) else {
                throw Abort(.badRequest, title: "Missing package version")
            }
            return version
        }
    }

    var fetchPackageMetadataURL: String {
        get throws {
            "\(serverURL)/\(try packageScope.value)/\(try packageName.value)/\(try packageVersion.value)"
        }
    }

    var unversionedManifestURL: String {
        get throws {
            "\(try fetchPackageMetadataURL)/Package.swift"
        }
    }

    func checkAcceptHeader(expectedMediaType: SwiftRegistryAcceptHeader.MediaType = .json) throws {
        guard let acceptHeaderRawValue = self.headers[.accept].first else {
            // The spec says the client SHOULD set the Accept header,
            // so it's not an error if they don't.
            return
        }
        let acceptHeader: SwiftRegistryAcceptHeader
        do {
            acceptHeader = try SwiftRegistryAcceptHeader(acceptHeaderRawValue)
        } catch let acceptHeaderError as SwiftRegistryAcceptHeader.Error {
            switch acceptHeaderError {
            case .notASwiftPackageRegistryAcceptHeader:
                let expectedHeader = SwiftRegistryAcceptHeader(version: .v1, mediaType: expectedMediaType)
                throw Abort(.badRequest, title: "Expected Accept header to be '\(expectedHeader)'")
            case .invalidVersion(let version):
                throw Abort(.badRequest, title: "Invalid Accept header version: '\(version)'")
            case .invalidMediaType(let mediaType):
                throw Abort(.unsupportedMediaType, title: "Invalid Accept header media type: '\(mediaType)'")
            }
        } catch {
            throw error
        }
        if acceptHeader.mediaType != expectedMediaType {
            // We got a valid Accept header, but the media type was not what we were expecting
            throw Abort(.unsupportedMediaType, title: "Expected Accept header media type to be '\(expectedMediaType)', but it was '\(acceptHeader.mediaType)'")
        }
    }
}

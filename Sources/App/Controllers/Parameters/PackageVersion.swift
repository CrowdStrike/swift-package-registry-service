import APIUtilities
import Vapor

struct PackageVersion {
    var value: String
    var isZip: Bool
}

extension PackageVersion: LosslessStringConvertible {
    var description: String { value }

    init?(_ description: String) {
        if description.hasSuffix(".json") {
            value = String(description.dropLast(5))
            isZip = false
        } else if description.hasSuffix(".zip") {
            value = String(description.dropLast(4))
            isZip = true
        } else {
            value = description
            isZip = false
        }
    }
}

extension PackageVersion {

    var semanticVersion: Version {
        get throws {
            do {
                return try .init(versionString: value)
            } catch let versionError as VersionError {
                throw Abort(.badRequest, title: "Semantic Version error: \(versionError.description)")
            } catch {
                throw Abort(.badRequest, title: "Invalid semantic version.")
            }
        }
    }
}

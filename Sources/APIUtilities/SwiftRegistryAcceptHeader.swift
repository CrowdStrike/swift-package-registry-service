import RegexBuilder

public struct SwiftRegistryAcceptHeader: Equatable, Sendable {
    public var version: Version
    public var mediaType: MediaType

    public enum Version: String, Equatable, Sendable {
        case v1 = "1"
    }
    public enum MediaType: String, Equatable, Sendable {
        case json
        case zip
        case swift
    }

    public init(version: Version, mediaType: MediaType) {
        self.version = version
        self.mediaType = mediaType
    }
}

extension SwiftRegistryAcceptHeader: CustomStringConvertible {

    public var description: String {
        "application/vnd.swift.registry.v" + version.rawValue + "+" + mediaType.rawValue
    }
}

extension SwiftRegistryAcceptHeader {
    public init(_ string: String) throws {
        let headerRegex = Regex {
            "application/vnd.swift.registry.v"

            Capture {
                OneOrMore(.word)
            }

            "+"

            Capture {
                OneOrMore(.word)
            }
        }

        guard let result = try headerRegex.wholeMatch(in: string) else {
            throw Error.notASwiftPackageRegistryAcceptHeader
        }
        let capture1 = String(result.output.1)
        guard let version = Version(rawValue: capture1) else {
            throw Error.invalidVersion(capture1)
        }
        let capture2 = String(result.output.2)
        guard let mediaType = MediaType(rawValue: capture2) else {
            throw Error.invalidMediaType(capture2)
        }
        self = .init(version: version, mediaType: mediaType)
    }

    public enum Error: Swift.Error {
        case notASwiftPackageRegistryAcceptHeader
        case invalidVersion(String)
        case invalidMediaType(String)
    }
}

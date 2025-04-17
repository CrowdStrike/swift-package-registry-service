import RegexBuilder

extension APIUtilities {
    public enum Manifest {
        public struct File: Equatable, Sendable {
            public var fileName: FileName
            public var swiftToolsVersion: String?

            public init(fileName: FileName, swiftToolsVersion: String? = nil) {
                self.fileName = fileName
                self.swiftToolsVersion = swiftToolsVersion
            }
        }

        public enum FileName: Equatable, Sendable {
            case unversioned
            case versioned(String)

            public var swiftVersion: String? {
                switch self {
                case .unversioned: nil
                case .versioned(let versionString): versionString
                }
            }

            public var fileName: String {
                switch self {
                case .unversioned: "Package.swift"
                case .versioned(let swiftVersion): "Package@swift-\(swiftVersion).swift"
                }
            }

            public var queryArguments: String {
                switch self {
                case .unversioned: ""
                case .versioned(let swiftVersion): "?swift-version=\(swiftVersion)"
                }
            }
        }

        public static func fileNames(from fileNames: [String]) throws -> [FileName] {
            let versionPattern = Regex {
                OneOrMore(.digit)
                ZeroOrMore {
                    "."
                    OneOrMore(.digit)
                }
            }

            let manifestFileNamePattern = Regex {
                "Package"
                Optionally {
                    "@swift-"
                    Capture {
                        versionPattern
                    }
                }
                ".swift"
            }

            return try fileNames
                .compactMap { try manifestFileNamePattern.wholeMatch(in: $0)?.output }
                .map { output in
                    if let version = output.1 {
                        return FileName.versioned(String(version))
                    } else {
                        return FileName.unversioned
                    }
                }
        }
    }
}

import HTTPTypes

extension GithubAPIClient {
    public enum GetContent {
        public struct Input: Equatable, Sendable {
            public var owner: String
            public var repo: String
            public var path: PathType
            public var ref: String?

            public init(owner: String, repo: String, path: PathType, ref: String? = nil) {
                self.owner = owner
                self.repo = repo
                self.path = path
                self.ref = ref
            }

            public enum PathType: Equatable, Sendable {
                /// This requests to receive the root directory of the repository.
                /// When we request this, we will use `Accept: application/vnd.github.object+json`
                /// in order to receive the directory as an object.
                case directory
                /// This requests to receive a specific file in the root directory of the repository
                /// This could be `Package.swift` or a Swift-version-specific file, like `Package@swift-6.0.swift`.
                /// When we request this, we will use `Accept: application/vnd.github.raw+json`
                /// so that we receive the raw file.
                case file(String)
            }
        }

        public enum Output: Equatable, Sendable {
            case ok(OKBody)  // 200
            case found       // 302
            case notModified // 304
            case forbidden   // 403
            case notFound    // 404
            case other(HTTPResponse)
        }

        public enum OKBody: Equatable, Sendable {
            case directory(Directory)
            case file(File)
            case submodule(Submodule)
            case symlink(Symlink)

            public struct Directory: Codable, Equatable, Sendable {
                public var entries: [Entry]

                public init(entries: [Entry] = []) {
                    self.entries = entries
                }

                public struct Entry: Codable, Equatable, Sendable {
                    public var name: String
                    public var size: Int
                    public var entryType: EntryType

                    public init(name: String, size: Int, entryType: EntryType) {
                        self.name = name
                        self.size = size
                        self.entryType = entryType
                    }

                    public enum EntryType: String, Codable, Equatable, Sendable {
                        case dir
                        case file
                        case submodule
                        case symlink
                    }
                }
            }

            public struct File: Equatable, Sendable {
                public var encoding: String
                public var size: Int
                public var name: String
                public var path: String
                public var content: String

                public init(encoding: String, size: Int, name: String, path: String, content: String) {
                    self.encoding = encoding
                    self.size = size
                    self.name = name
                    self.path = path
                    self.content = content
                }
            }

            public struct Submodule: Equatable, Sendable {
                public var submoduleGitUrl: String
                public var size: Int
                public var name: String
                public var path: String
                public var sha: String
                public var url: String

                public init(submoduleGitUrl: String, size: Int, name: String, path: String, sha: String, url: String) {
                    self.submoduleGitUrl = submoduleGitUrl
                    self.size = size
                    self.name = name
                    self.path = path
                    self.sha = sha
                    self.url = url
                }
            }

            public struct Symlink: Equatable, Sendable {
                public var target: Swift.String
                public var size: Swift.Int
                public var name: Swift.String
                public var path: Swift.String
                public var sha: Swift.String
                public var url: Swift.String

                public init(target: String, size: Int, name: String, path: String, sha: String, url: String) {
                    self.target = target
                    self.size = size
                    self.name = name
                    self.path = path
                    self.sha = sha
                    self.url = url
                }
            }
        }
    }
}

extension GithubAPIClient.GetContent.OKBody.Directory.Entry.EntryType {
    var isFile: Bool {
        switch self {
        case .file: return true
        default: return false
        }
    }
}

extension GithubAPIClient.GetContent.OKBody.Directory.Entry {
    var isFileEntry: Bool { entryType.isFile }
}

extension GithubAPIClient.GetContent.Output {
    public var directoryFileNames: [String] {
        switch self {
        case .ok(let okBody):
            switch okBody {
            case .directory(let directory): return directory.entries.filter(\.isFileEntry).map(\.name)
            default: return []
            }
        default: return []
        }
    }
}

extension GithubAPIClient.GetContent.Input {
    public static let mockFile = Self(
        owner: "pointfreeco",
        repo: "swift-overture",
        path: .file("Package.swift"),
        ref: "0.5.0"
    )
    public static let mockFileVersioned = Self(
        owner: "pointfreeco",
        repo: "swift-overture",
        path: .file("Package@swift-6.0.swift"),
        ref: "0.5.0"
    )
    public static let mockDirectory = Self(
        owner: "pointfreeco",
        repo: "swift-overture",
        path: .directory,
        ref: "0.5.0"
    )
}

extension GithubAPIClient.GetContent.OKBody {
    public var outputType: String {
        switch self {
        case .directory: "directory"
        case .file: "file"
        case .submodule: "submodule"
        case .symlink: "symlink"
        }
    }

    public static let mockFile: Self = .file(
        .init(
            encoding: "base64",
            size: 1328,
            name: "Package.swift",
            path: "Package.swift",
            content: """
            Ly8gc3dpZnQtdG9vbHMtdmVyc2lvbjogNS45CgppbXBvcnQgUGFja2FnZURl
            c2NyaXB0aW9uCgpsZXQgcGFja2FnZSA9IFBhY2thZ2UoCiAgbmFtZTogInN3
            aWZ0LWNsb2NrcyIsCiAgLy8gTkI6IFdoaWxlIHRoZSBgQ2xvY2tgIHByb3Rv
            Y29sIGlzIGlPUyAxNissIGV0Yy4sIHRoZSBwYWNrYWdlIHNob3VsZCBzdXBw
            b3J0IGVhcmxpZXIgcGxhdGZvcm1zCiAgLy8gICAgIHNvIHRoYXQgZGVwZW5k
            aW5nIGxpYnJhcmllcyBhbmQgYXBwbGljYXRpb25zIGNhbiBjb25kaXRpb25h
            bGx5IHVzZSB0aGUgbGlicmFyeSB2aWEKICAvLyAgICAgYXZhaWxhYmlsaXR5
            IGNoZWNrcy4KICBwbGF0Zm9ybXM6IFsKICAgIC5pT1MoLnYxMyksCiAgICAu
            bWFjT1MoLnYxMF8xNSksCiAgICAudHZPUygudjEzKSwKICAgIC53YXRjaE9T
            KC52NiksCiAgXSwKICBwcm9kdWN0czogWwogICAgLmxpYnJhcnkoCiAgICAg
            IG5hbWU6ICJDbG9ja3MiLAogICAgICB0YXJnZXRzOiBbIkNsb2NrcyJdCiAg
            ICApCiAgXSwKICBkZXBlbmRlbmNpZXM6IFsKICAgIC5wYWNrYWdlKHVybDog
            Imh0dHBzOi8vZ2l0aHViLmNvbS9hcHBsZS9zd2lmdC1kb2NjLXBsdWdpbiIs
            IGZyb206ICIxLjAuMCIpLAogICAgLnBhY2thZ2UodXJsOiAiaHR0cHM6Ly9n
            aXRodWIuY29tL3BvaW50ZnJlZWNvL3N3aWZ0LWNvbmN1cnJlbmN5LWV4dHJh
            cyIsIGZyb206ICIxLjAuMCIpLAogICAgLnBhY2thZ2UodXJsOiAiaHR0cHM6
            Ly9naXRodWIuY29tL3BvaW50ZnJlZWNvL3hjdGVzdC1keW5hbWljLW92ZXJs
            YXkiLCBmcm9tOiAiMS4yLjIiKSwKICBdLAogIHRhcmdldHM6IFsKICAgIC50
            YXJnZXQoCiAgICAgIG5hbWU6ICJDbG9ja3MiLAogICAgICBkZXBlbmRlbmNp
            ZXM6IFsKICAgICAgICAucHJvZHVjdChuYW1lOiAiQ29uY3VycmVuY3lFeHRy
            YXMiLCBwYWNrYWdlOiAic3dpZnQtY29uY3VycmVuY3ktZXh0cmFzIiksCiAg
            ICAgICAgLnByb2R1Y3QobmFtZTogIklzc3VlUmVwb3J0aW5nIiwgcGFja2Fn
            ZTogInhjdGVzdC1keW5hbWljLW92ZXJsYXkiKSwKICAgICAgXQogICAgKSwK
            ICAgIC50ZXN0VGFyZ2V0KAogICAgICBuYW1lOiAiQ2xvY2tzVGVzdHMiLAog
            ICAgICBkZXBlbmRlbmNpZXM6IFsKICAgICAgICAiQ2xvY2tzIgogICAgICBd
            CiAgICApLAogIF0KKQoKZm9yIHRhcmdldCBpbiBwYWNrYWdlLnRhcmdldHMg
            ewogIHRhcmdldC5zd2lmdFNldHRpbmdzID0gdGFyZ2V0LnN3aWZ0U2V0dGlu
            Z3MgPz8gW10KICB0YXJnZXQuc3dpZnRTZXR0aW5ncyEuYXBwZW5kKGNvbnRl
            bnRzT2Y6IFsKICAgIC5lbmFibGVFeHBlcmltZW50YWxGZWF0dXJlKCJTdHJp
            Y3RDb25jdXJyZW5jeSIpCiAgXSkKfQo=
            """
        )
    )
    public static let mockDirectoryNoManifest: Self = .directory(.mockNoManifest)
    public static let mockDirectoryOneUnversionedManifest: Self = .directory(.mockOneUnversionedManifest)
    public static let mockDirectoryMultipleManifests: Self = .directory(.mockMultipleManifests)
}

extension GithubAPIClient.GetContent.Output {
    public static let mockFile: Self = .ok(.mockFile)
    public static let mockDirectoryNoManifest: Self = .ok(.mockDirectoryNoManifest)
    public static let mockDirectoryOneUnversionedManifest: Self = .ok(.mockDirectoryOneUnversionedManifest)
    public static let mockDirectoryMultipleManifests: Self = .ok(.mockDirectoryMultipleManifests)
}

extension GithubAPIClient.GetContent.OKBody.Directory {
    public static let mockNoManifest = Self(
        entries: [
            .init(name: ".circleci", size: 0, entryType: .dir),
            .init(name: ".gitignore", size: 1459, entryType: .file),
            .init(name: ".sourcery-templates", size: 0, entryType: .dir),
            .init(name: ".swift-version", size: 4, entryType: .file),
            .init(name: ".travis.yml", size: 298, entryType: .file),
            .init(name: "CODE_OF_CONDUCT.md", size: 3213, entryType: .file),
            .init(name: "Development.xcconfig", size: 114, entryType: .file),
            .init(name: "Dockerfile", size: 146, entryType: .file),
            .init(name: "Info.plist", size: 701, entryType: .file),
            .init(name: "LICENSE", size: 1073, entryType: .file),
            .init(name: "Makefile", size: 754, entryType: .file),
            .init(name: "Overture.playground", size: 0, entryType: .dir),
            .init(name: "Overture.podspec", size: 834, entryType: .file),
            .init(name: "Overture.xcodeproj", size: 0, entryType: .dir),
            .init(name: "Overture.xcworkspace", size: 0, entryType: .dir),
            .init(name: "README.md", size: 14313, entryType: .file),
            .init(name: "Sources", size: 0, entryType: .dir),
            .init(name: "Tests", size: 0, entryType: .dir),
            .init(name: "project.yml", size: 659, entryType: .file),
        ]
    )
    public static let mockOneUnversionedManifest = Self(
        entries: Self.mockNoManifest.entries + [.unversionedManifest]
    )
    public static let mockMultipleManifests = Self(
        entries: Self.mockNoManifest.entries + [.unversionedManifest, .versionedManifest4_5, .versionedManifest6_0]
    )
}

extension GithubAPIClient.GetContent.OKBody.Directory.Entry {
    public static let unversionedManifest = Self(name: "Package.swift", size: 576, entryType: .file)
    public static let versionedManifest6_0 = Self(name: "Package@swift-6.0.swift", size: 576, entryType: .file)
    public static let versionedManifest4_5 = Self(name: "Package@swift-4.5.swift", size: 576, entryType: .file)
}

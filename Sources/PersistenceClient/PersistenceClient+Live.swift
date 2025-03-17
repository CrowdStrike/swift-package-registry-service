import APIUtilities
import AsyncHTTPClient
import FileClient
import Foundation
import HTTPStreamClient
import NIOCore
import NIOFoundationCompat

extension PersistenceClient {

    public static func live(
        fileClient: FileClient,
        httpStreamClient: HTTPStreamClient,
        byteBufferAllocator: ByteBufferAllocator,
        cacheRootDirectory: String,
        githubAPIToken: String
    ) -> Self {
        .init(
            readTags: { owner, repo in
                let path = tagsFileName(cacheRootDirectory: cacheRootDirectory, owner: owner, repo: repo)
                let buffer = try await fileClient.readFile(path: path)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(TagFile.self, from: buffer)
            },
            saveTags: { owner, repo, tagFile in
                let path = tagsFileName(cacheRootDirectory: cacheRootDirectory, owner: owner, repo: repo)
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .default
                let buffer = try encoder.encodeAsByteBuffer(tagFile, allocator: byteBufferAllocator)
                try await fileClient.writeFile(buffer: buffer, path: path)
            },
            readReleases: { owner, repo in
                let path = releasesFileName(cacheRootDirectory: cacheRootDirectory, owner: owner, repo: repo)
                let buffer = try await fileClient.readFile(path: path)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([Release].self, from: buffer)
            },
            saveReleases: { releases in
                guard !releases.isEmpty else { return }
                // Ensure that all releases have same owner and repo
                let firstOwner = releases[0].owner
                let firstRepo = releases[0].repo
                guard releases.allSatisfy({ $0.owner == firstOwner && $0.repo == firstRepo }) else {
                    throw PersistenceClientError.releasesHaveMixedOwnerRepo
                }
                let path = releasesFileName(cacheRootDirectory: cacheRootDirectory, owner: firstOwner, repo: firstRepo)
                // Sort the releases newest-to-oldest
                let sortedReleases = releases.sorted(by: >)
                // Serialize the sorted list of releases
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .default
                let byteBuffer = try encoder.encodeAsByteBuffer(sortedReleases, allocator: byteBufferAllocator)
                try await fileClient.writeFile(buffer: byteBuffer, path: path)
            },
            saveZipBall: { owner, repo, version, zipBallURL in
                // Fetch the entire zipBall into memory. TODO: Improve this by passing chunk-by-chunk into FileClient
                let zipBytes = try await Self.fetchZipBall(url: zipBallURL, apiToken: githubAPIToken, httpStreamClient: httpStreamClient)
                let cachedFileName = zipBallFileName(cacheRootDirectory: cacheRootDirectory, owner: owner, repo: repo, version: version)
                try await fileClient.writeFile(buffer: zipBytes, path: cachedFileName)
                return cachedFileName
            },
            readReleaseMetadata: { owner, repo, version in
                let cachedFileName = releaseMetadataFileName(cacheRootDirectory: cacheRootDirectory, owner: owner, repo: repo, version: version)
                let byteBuffer: ByteBuffer
                do {
                    byteBuffer = try await fileClient.readFile(path: cachedFileName)
                } catch {
                    // We failed to read the file. Return nil
                    return nil
                }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(ReleaseMetadata.self, from: byteBuffer)
            },
            saveReleaseMetadata: { owner, repo, metadata in
                let cachedFileName = releaseMetadataFileName(cacheRootDirectory: cacheRootDirectory, owner: owner, repo: repo, version: metadata.version)
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .default
                let byteBuffer = try encoder.encodeAsByteBuffer(metadata, allocator: byteBufferAllocator)
                try await fileClient.writeFile(buffer: byteBuffer, path: cachedFileName)
            },
            readSourceArchive: { owner, repo, version in
                let cachedFileName = zipBallFileName(cacheRootDirectory: cacheRootDirectory, owner: owner, repo: repo, version: version)
                let byteBuffer: ByteBuffer
                do {
                    byteBuffer = try await fileClient.readFile(path: cachedFileName)
                } catch {
                    return nil
                }
                return .init(fileName: cachedFileName, byteBuffer: byteBuffer)
            },
            readManifests: { owner, repo, version in
                // Read and deserialize the manifest directory file. This could fail if we haven't cached anything yet.
                let manifestDirectoryFileName = Self.manifestDirectoryFileName(
                    cacheRootDirectory: cacheRootDirectory,
                    owner: owner,
                    repo: repo,
                    version: version
                )
                let byteBuffer: ByteBuffer
                do {
                    byteBuffer = try await fileClient.readFile(path: manifestDirectoryFileName)
                } catch {
                    return []
                }
                let manifestDirectory = try JSONDecoder().decode(ManifestDirectory.self, from: byteBuffer)
                guard !manifestDirectory.manifests.isEmpty else {
                    return []
                }
                // Read in the manifest files in parallel
                return try await withThrowingTaskGroup(of: Manifest.self, returning: [Manifest].self) { group in
                    manifestDirectory.manifests.forEach { manifest in
                        group.addTask {
                            let manifestFileName = Self.manifestFileName(
                                cacheRootDirectory: cacheRootDirectory,
                                owner: owner,
                                repo: repo,
                                version: version,
                                manifest: manifest
                            )
                            let contents = try await fileClient.readFile(path: manifestFileName)
                            return Manifest(
                                fileName: manifest.fileName,
                                swiftVersion: manifest.swiftVersion,
                                swiftToolsVersion: manifest.swiftToolsVersion,
                                contents: contents
                            )
                        }
                    }
                    var manifests = [Manifest]()
                    for try await manifest in group {
                        manifests.append(manifest)
                    }
                    return manifests
                }
            },
            saveManifests: { owner, repo, version, manifests in
                guard !manifests.isEmpty else { return }
                guard manifests.allSatisfy(\.hasContents) else {
                    throw PersistenceClientError.manifestHasNoContents
                }
                // Save the manifest file contents out in parallel
                try await withThrowingTaskGroup(of: Void.self) { group in
                    manifests.forEach { manifest in
                        guard let contents = manifest.contents else { return }
                        group.addTask {
                            let filePath = Self.manifestFileName(
                                cacheRootDirectory: cacheRootDirectory,
                                owner: owner,
                                repo: repo,
                                version: version,
                                manifest: manifest
                            )
                            try await fileClient.writeFile(buffer: contents, path: filePath)
                        }
                    }
                    try await group.waitForAll()
                }
                // Serialize the manifest directory file
                let encoder = JSONEncoder()
                encoder.outputFormatting = .default
                let directory = ManifestDirectory(manifests: manifests)
                let manifestDirectoryFileName = Self.manifestDirectoryFileName(
                    cacheRootDirectory: cacheRootDirectory,
                    owner: owner,
                    repo: repo,
                    version: version
                )
                let byteBuffer = try encoder.encodeAsByteBuffer(directory, allocator: byteBufferAllocator)
                try await fileClient.writeFile(buffer: byteBuffer, path: manifestDirectoryFileName)
            },
            readRepositories: {
                let repositoriesFileName = Self.repositoriesFileName(cacheRootDirectory: cacheRootDirectory)
                let byteBuffer: ByteBuffer
                do {
                    byteBuffer = try await fileClient.readFile(path: repositoriesFileName)
                } catch {
                    return RepositoriesFile()
                }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(RepositoriesFile.self, from: byteBuffer)
            },
            saveRepositories: { repositoriesFile in
                let repositoriesFileName = Self.repositoriesFileName(cacheRootDirectory: cacheRootDirectory)
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .default
                let byteBuffer = try encoder.encodeAsByteBuffer(repositoriesFile, allocator: byteBufferAllocator)
                try await fileClient.writeFile(buffer: byteBuffer, path: repositoriesFileName)
            }
        )
    }

    private static func tagsFileName(cacheRootDirectory: String, owner: String, repo: String) -> String {
        let cacheRootDirectoryWithSlash = cacheRootDirectory.ending(with: "/")
        return "\(cacheRootDirectoryWithSlash)\(owner)/\(repo)/tags.json"
    }

    private static func releasesFileName(cacheRootDirectory: String, owner: String, repo: String) -> String {
        let cacheRootDirectoryWithSlash = cacheRootDirectory.ending(with: "/")
        return "\(cacheRootDirectoryWithSlash)\(owner)/\(repo)/releases.json"
    }

    private static func zipBallFileName(cacheRootDirectory: String, owner: String, repo: String, version: Version) -> String {
        let cacheRootDirectoryWithSlash = cacheRootDirectory.ending(with: "/")
        return "\(cacheRootDirectoryWithSlash)\(owner)/\(repo)/\(version)/\(owner)-\(repo)-\(version).zip"
    }

    private static func releaseMetadataFileName(cacheRootDirectory: String, owner: String, repo: String, version: Version) -> String {
        let cacheRootDirectoryWithSlash = cacheRootDirectory.ending(with: "/")
        return "\(cacheRootDirectoryWithSlash)\(owner)/\(repo)/\(version)/releaseMetadata.json"
    }

    private static func manifestDirectoryFileName(cacheRootDirectory: String, owner: String, repo: String, version: Version) -> String {
        let cacheRootDirectoryWithSlash = cacheRootDirectory.ending(with: "/")
        return "\(cacheRootDirectoryWithSlash)\(owner)/\(repo)/\(version)/manifests.json"
    }

    private static func repositoriesFileName(cacheRootDirectory: String) -> String {
        let cacheRootDirectoryWithSlash = cacheRootDirectory.ending(with: "/")
        return "\(cacheRootDirectoryWithSlash)repositories.json"
    }

    private static func manifestFileName(
        cacheRootDirectory: String,
        owner: String,
        repo: String,
        version: Version,
        manifest: Manifest
    ) -> String {
        let cacheRootDirectoryWithSlash = cacheRootDirectory.ending(with: "/")
        return "\(cacheRootDirectoryWithSlash)\(owner)/\(repo)/\(version)/\(manifest.fileName)"
    }

    private static func fetchZipBall(
        url: String,
        apiToken: String,
        httpStreamClient: HTTPStreamClient
    ) async throws -> ByteBuffer {
        // Fetch the zipBallURL
        var request = HTTPClientRequest(url: url)
        request.headers.add(
            name: "User-Agent",
            value: "async-http-client/1.24.2"
        )
        request.headers.add(
            name: "Authorization",
            value: "Bearer \(apiToken)"
        )
        let response = try await httpStreamClient.execute(request)

        guard response.status == .ok else {
            throw PersistenceClientError.couldNotDownloadZipBall(Int(response.status.code))
        }

        // If defined, the content-length headers announces the size of the body
        let maxBytes: Int
        if let contentLength = response.headers.first(name: "Content-Length").flatMap(Int.init) {
            maxBytes = contentLength
        } else {
            maxBytes = 1024 * 1024 * 1024
        }

        // For now, we just collect the whole zip file in memory and then
        // return it to the response.
        return try await response.body.collect(upTo: maxBytes)
    }
}

private extension String {
    func ending(with string: String) -> String {
        if !self.hasSuffix(string) {
            return self + string
        } else {
            return self
        }
    }
}

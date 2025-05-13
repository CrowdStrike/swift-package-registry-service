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
            }
        )
    }

    private static func tagsFileName(cacheRootDirectory: String, owner: String, repo: String) -> String {
        let cacheRootDirectoryWithSlash = cacheRootDirectory.ending(with: "/")
        return "\(cacheRootDirectoryWithSlash)\(owner)/\(repo)/tags.json"
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

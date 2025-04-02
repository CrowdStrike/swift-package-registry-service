import NIOCore
import _NIOFileSystem
import NIOPosix
import Overture

extension FileClient {

    public static func live(
        fileSystem: FileSystem = .shared
    ) -> Self {
        let fileClientActor = FileClientActor(fileSystem: fileSystem)
        return .init(
            readFile: { pathString in
                let path = FilePath(pathString)
                guard let fileSize = try await fileSystem.info(forFileAt: path)?.size else {
                    throw FileClientError.fileNotFound(pathString)
                }
                return try await fileSystem.withFileHandle(forReadingAt: path) { handle in
                    return try await handle.readChunk(fromAbsoluteOffset: 0, length: .bytes(fileSize))
                }
            },
            writeFile: { buffer, pathString in
                let filePath = FilePath(pathString)
                let dirPath = filePath.removingLastComponent()
                let directoryExists = try await Self.directoryExists(at: dirPath, fileSystem: fileSystem)
                if !directoryExists {
                    try await fileClientActor.createDirectoryWithIntermediateDirectories(at: dirPath)
                }
                // This returns the number of bytes written which we don't need
                _ = try await fileSystem.withFileHandle(forWritingAt: filePath, options: .newFile(replaceExisting: true)) { handle in
                    try await handle.write(contentsOf: buffer, toAbsoluteOffset: 0)
                }
            }
        )
    }

    static func directoryExists(at path: FilePath, fileSystem: FileSystem) async throws -> Bool {
        do {
            return try await fileSystem.withDirectoryHandle(atPath: path) { _ in true }
        } catch let fileSystemError as FileSystemError {
            switch fileSystemError.code {
            case .notFound:
                return false
            default:
                throw fileSystemError
            }
        } catch {
            throw error
        }
    }
}

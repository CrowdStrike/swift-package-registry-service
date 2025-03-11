import NIOCore
import _NIOFileSystem
import NIOPosix
import Overture

extension FileClient {

    public static func live(
        nonBlockingFileIO: NonBlockingFileIO,
        byteBufferAllocator: ByteBufferAllocator
    ) -> Self {
        .init(
            readFile: { path in
                guard let fileSize = try await FileSystem.shared.info(forFileAt: .init(path))?.size else {
                    throw FileClientError.fileNotFound(path)
                }
                return try await FileSystem.shared.withFileHandle(forReadingAt: .init(path)) { handle in
                    return try await handle.readChunk(fromAbsoluteOffset: 0, length: .bytes(fileSize))
                }
            },
            writeFile: { buffer, path in
                try await Self.ensureDirectoryExists(at: path)
                // This returns the number of bytes written which we don't need
                _ = try await FileSystem.shared.withFileHandle(forWritingAt: .init(path), options: .newFile(replaceExisting: true)) { handle in
                    try await handle.write(contentsOf: buffer, toAbsoluteOffset: 0)
                }
            }
        )
    }

    private static func ensureDirectoryExists(at path: String) async throws {
        let fileSystem = FileSystem.shared
        let dirPath = FilePath(path).removingLastComponent()
        // Try to create this directory
        do {
            try await fileSystem.createDirectory(
                at: dirPath,
                withIntermediateDirectories: true,
                permissions: [.ownerReadWriteExecute, .groupReadWriteExecute, .otherReadWriteExecute]
            )
        } catch let fileSystemError as FileSystemError {
            if fileSystemError.code == .fileAlreadyExists {
                return
            } else {
                throw fileSystemError
            }
        } catch {
            throw error
        }
    }
}

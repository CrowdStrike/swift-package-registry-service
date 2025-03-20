import NIOFileSystem
import Semaphore

actor FileClientActor {
    private let semaphore = AsyncSemaphore(value: 1)
    private let fileSystem: FileSystem

    init(fileSystem: FileSystem) {
        self.fileSystem = fileSystem
    }

    func createDirectoryWithIntermediateDirectories(at path: FilePath) async throws {
        await semaphore.wait()
        defer { semaphore.signal() }

        do {
            // Try to create this directory
            try await FileSystem.shared.createDirectory(
                at: path,
                withIntermediateDirectories: true,
                permissions: [.ownerReadWriteExecute, .groupReadExecute, .otherReadExecute]
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

@testable import FileClient
import NIOCore
import _NIOFileSystem
import Testing

struct FileClientTests {

    @Test func overlappingWrites() async throws {
        let fileSystem = FileSystem.shared
        let fileClient = FileClient.live(fileSystem: fileSystem)
        // Create a temporary directory
        let tempDir = try await fileSystem.temporaryDirectory
        // Create a series of FilePath's in this pattern
        // <tmp-dir>/dir0/file0.txt
        // <tmp-dir>/dir0/dir1/file1.txt
        // <tmp-dir>/dir0/dir1/dir2/file2.txt
        // <tmp-dir>/dir0/dir1/dir2/dir3/file3.txt
        // <tmp-dir>/dir0/dir1/dir2/dir3/dir4/file4.txt
        // <tmp-dir>/dir0/dir1/dir2/dir3/dir4/dir5/file5.txt
        // ...
        var filePaths = [FilePath]()
        var curDir = tempDir
        for i in 0..<20 {
            let newDir = curDir.appending("dir\(i)")
            let newFile = newDir.appending("file\(i).txt")
            filePaths.append(newFile)
            curDir = newDir
        }
        // Randomize the order
        let randomizedFilePaths = filePaths.shuffled()
        // Now attempt to write to these files concurrently
        let fileContents = ByteBuffer(string: "File Contents")
        try await withThrowingTaskGroup(of: Void.self) { group in
            for filePath in randomizedFilePaths {
                group.addTask {
                    do {
                        try await fileClient.writeFile(buffer: fileContents, path: filePath.string)
                        print("Created \(filePath.string)")
                    } catch {
                        print("Error creating \(filePath.string): \(error)")
                        throw error
                    }
                }
            }
            try await group.waitForAll()
        }
        // Now clean up the created files and directories
        var mutableFilePaths = filePaths
        while !mutableFilePaths.isEmpty {
            let lastFilePath = mutableFilePaths.removeLast()
            try await fileSystem.removeItem(at: lastFilePath)
            let lastDirPath = lastFilePath.removingLastComponent()
            try await fileSystem.removeItem(at: lastDirPath)
        }
    }
}

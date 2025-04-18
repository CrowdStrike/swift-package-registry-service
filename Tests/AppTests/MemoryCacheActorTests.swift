@testable import App
import APIUtilities
import ConcurrencyExtras
import Testing
import Vapor

struct MemoryCacheActorTests {

    // Comment out test until MemoryCacheActor can be re-worked to use
    // generics for input and config.
//    @Test func sameInputMakesOneCallToDataLoader() async throws {
//        let concurrentDataLoadersLocked = LockIsolated(0)
//        let memoryCacheActor = MemoryCacheActor<Int> { owner, repo, version, logger in
//            // Increment the count of the times the dataLoader executes
//            concurrentDataLoadersLocked.withValue { $0 += 1 }
//            return 0
//        }
//
//        let logger = Logger(label: "test")
//
//        // Now spin up 10 identical calls
//        try await withThrowingTaskGroup(of: Void.self) { group in
//            for _ in 0..<10 {
//                group.addTask {
//                    _ = try await memoryCacheActor.loadData(owner: "foo", repo: "bar", version: Version(1, 0, 0), logger: logger)
//                }
//            }
//
//            try await group.waitForAll()
//        }
//
//        #expect(concurrentDataLoadersLocked.value == 1)
//    }

    // Comment out test until MemoryCacheActor can be re-worked to use
    // generics for input and config.
//    @Test func differentInputMakesMultipleCallsToDataLoader() async throws {
//        let concurrentDataLoadersLocked = LockIsolated(0)
//        let memoryCacheActor = MemoryCacheActor<Int> { owner, repo, version, logger in
//            // Increment the count of the times the dataLoader executes
//            concurrentDataLoadersLocked.withValue { $0 += 1 }
//            return 0
//        }
//
//        let logger = Logger(label: "test")
//        let callCount = 10
//
//        // Now spin up calls with different values of repo
//        try await withThrowingTaskGroup(of: Void.self) { group in
//            for i in 0..<callCount {
//                group.addTask {
//                    _ = try await memoryCacheActor.loadData(owner: "foo", repo: "bar\(i)", version: Version(1, 0, 0), logger: logger)
//                }
//            }
//
//            try await group.waitForAll()
//        }
//
//        #expect(concurrentDataLoadersLocked.value == callCount)
//    }
}

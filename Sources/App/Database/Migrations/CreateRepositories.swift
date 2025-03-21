import Fluent

struct CreateRepositories: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("repositories")
            .id()
            .field("github_id", .int64)
            .field("html_url", .string)
            .field("clone_url", .string)
            .field("ssh_url", .string)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("repositories").delete()
    }
}

import Fluent

struct CreateManifests: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("manifests")
            .id()
            .field("package_scope", .string, .required)
            .field("package_name", .string, .required)
            .field("package_version", .string, .required)
            .field("swift_version", .string)
            .field("swift_tools_version", .string, .required)
            .field("cache_file_name", .string, .required)
            .unique(on: "package_scope", "package_name", "package_version", "swift_version")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("manifests").delete()
    }
}

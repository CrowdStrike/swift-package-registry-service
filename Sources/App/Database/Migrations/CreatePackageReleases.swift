import Fluent

struct CreatePackageReleases: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("package_releases")
            .id()
            .field("package_scope", .string, .required)
            .field("package_name", .string, .required)
            .field("package_version", .string, .required)
            .field("tag_name", .string, .required)
            .field("published_at", .datetime)
            .field("zip_ball_url", .string, .required)
            .field("cache_file_name", .string, .required)
            .field("checksum", .string, .required)
            .unique(on: "package_scope", "package_name", "package_version")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("package_releases").delete()
    }
}

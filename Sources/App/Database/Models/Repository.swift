import Fluent
import Foundation
import Vapor

final class Repository: Model, @unchecked Sendable {
    static let schema = "repositories"

    @ID(key: .id)
    var id: UUID?

    // This is the id returned from the Github API
    @Field(key: "github_id")
    var gitHubId: Int64

    @Field(key: "html_url")
    var htmlUrl: String

    @Field(key: "clone_url")
    var cloneUrl: String

    @Field(key: "ssh_url")
    var sshUrl: String

    init() { }

    init(
        id: UUID? = nil,
        gitHubId: Int64,
        htmlUrl: String,
        cloneUrl: String,
        sshUrl: String
    ) {
        self.id = id
        self.gitHubId = gitHubId
        self.htmlUrl = htmlUrl
        self.cloneUrl = cloneUrl
        self.sshUrl = sshUrl
    }
}

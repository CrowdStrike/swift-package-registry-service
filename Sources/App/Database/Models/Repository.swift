import Fluent
import Foundation
import Vapor

final class Repository: Model, @unchecked Sendable {
    static let schema = "repositories"

    @ID(custom: .id, generatedBy: .user)
    var id: Int64?

    @Field(key: "html_url")
    var htmlUrl: String

    @Field(key: "clone_url")
    var cloneUrl: String

    @Field(key: "ssh_url")
    var sshUrl: String

    init() { }

    init(
        id: Int64,
        htmlUrl: String,
        cloneUrl: String,
        sshUrl: String
    ) {
        self.id = id
        self.htmlUrl = htmlUrl
        self.cloneUrl = cloneUrl
        self.sshUrl = sshUrl
    }
}

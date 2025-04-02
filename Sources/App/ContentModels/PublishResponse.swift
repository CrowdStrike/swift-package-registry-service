import Vapor

struct PublishResponse: Content {
    var message: String?
    var url: String?
}

extension PublishResponse {
    static let mock = Self(
        message: "Package release successfully published",
        url: "http://127.0.0.1:8080/pointfreeco/swift-overture/0.5.0"
    )
}

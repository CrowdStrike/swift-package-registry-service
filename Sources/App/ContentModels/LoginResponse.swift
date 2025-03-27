import Vapor

struct LoginResponse: Content {
    var success: Bool
}

extension LoginResponse {

    static let mock = Self(success: true)
}

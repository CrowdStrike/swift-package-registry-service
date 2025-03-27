import Foundation
import HTTPTypes
import OpenAPIRuntime

public struct ClientAuthMiddleware {
    let bearerToken: String

    public init(bearerToken: String) {
        self.bearerToken = bearerToken
    }
}

extension ClientAuthMiddleware: ClientMiddleware {

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[.authorization] = "bearer \(bearerToken)"
        return try await next(request, body, baseURL)
    }
}

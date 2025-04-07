import Foundation
import HTTPTypes
import OpenAPIRuntime

public struct ClientStaticHeadersMiddleware {
    let headers: [HTTPField.Name: String]

    public init(headers: [HTTPField.Name: String] = [:]) {
        self.headers = headers
    }
}

extension ClientStaticHeadersMiddleware: ClientMiddleware {

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        headers.forEach { request.headerFields[$0.key] = $0.value }
        return try await next(request, body, baseURL)
    }
}

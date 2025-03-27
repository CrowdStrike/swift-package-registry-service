import Vapor

struct CustomRouteLoggingMiddleware: AsyncMiddleware {
    public let logLevel: Logger.Level

    public init(logLevel: Logger.Level = .info) {
        self.logLevel = logLevel
    }

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let path = request.url.path.removingPercentEncoding ?? request.url.path
        let decodedQuery = request.url.query?.removingPercentEncoding
        let query = decodedQuery.map { "?\($0)" } ?? ""
        let requestInfo = "\(request.method) \(path)\(query)"
        request.logger.log(level: self.logLevel, "Request \(requestInfo)")
        let response = try await next.respond(to: request)
        let responseLogLevel: Logger.Level = response.status.code >= 400 ? .error : self.logLevel
        request.logger.log(level: responseLogLevel, "Response \(requestInfo) \(response.status.code)")
        return response
    }
}

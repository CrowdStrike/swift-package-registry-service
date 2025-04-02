import Foundation
import NIOCore
import NIOHTTP1
import Vapor

/// Similar to Vapor's default `ErrorMiddleware`, but serializes to RFC7807's `ProblemDetails`.
final class ProblemDetailsErrorMiddleware: Middleware {
    /// Create a default `ProblemDetailsErrorMiddleware`. Logs errors to a `Logger` based on `Environment`
    /// and converts `Error` to `ProblemDetails` based on conformance to `AbortError` and `DebuggableError`.
    ///
    /// - parameters:
    ///     - environment: The environment to respect when presenting errors.
    public static func `default`(environment: Environment) -> ErrorMiddleware {
        return .init { req, error in
            let status: HTTPResponseStatus
            let title: String
            let source: ErrorSource
            var headers: HTTPHeaders

            // Inspect the error type and extract what data we can.
            switch error {
            case let debugAbortError as (DebuggableError & AbortError):
                status = debugAbortError.status
                title = debugAbortError.reason
                headers = debugAbortError.headers
                source = debugAbortError.source ?? .capture()
            case let abortError as AbortError:
                status = abortError.status
                title = abortError.reason
                headers = abortError.headers
                source = .capture()
            case let debuggableError as DebuggableError:
                status = .internalServerError
                title = debuggableError.reason
                headers = [:]
                source = debuggableError.source ?? .capture()
            default:
                status = .internalServerError
                title = environment.isRelease ? "Something went wrong." : String(describing: error)
                headers = [:]
                source = .capture()
            }

            // Report the error
            req.logger.report(
                error: error,
                metadata: [
                    "method" : "\(req.method.rawValue)",
                    "url" : "\(req.url.string)",
                    "userAgent" : .array(req.headers["User-Agent"].map { "\($0)" })
                ],
                file: source.file,
                function: source.function,
                line: source.line
            )

            // Attempt to serialize the error to json
            let body: Response.Body
            do {
                let encoder = try ContentConfiguration.global.requireEncoder(for: .json)
                var byteBuffer = req.byteBufferAllocator.buffer(capacity: 0)
                let problemDetails = ProblemDetails(title: title, status: Int(status.code))
                try encoder.encode(problemDetails, to: &byteBuffer, headers: &headers)

                body = .init(
                    buffer: byteBuffer,
                    byteBufferAllocator: req.byteBufferAllocator
                )
            } catch {
                body = .init(
                    string: "Oops: \(String(describing: error))\nWhile encoding error: \(title)",
                    byteBufferAllocator: req.byteBufferAllocator
                )
                headers.contentType = .plainText
            }

            // create a Response with appropriate status
            return Response(status: status, headers: headers, body: body)
        }
    }

    /// Error-handling closure.
    private let closure: @Sendable (Request, Error) -> (Response)

    /// Create a new `ProblemDetailsErrorMiddleware`.
    ///
    /// - parameters:
    ///     - closure: Error-handling closure. Converts `Error` to `Response`.
    @preconcurrency public init(_ closure: @Sendable @escaping (Request, Error) -> (Response)) {
        self.closure = closure
    }

    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).flatMapErrorThrowing { error in
            self.closure(request, error)
        }
    }
}

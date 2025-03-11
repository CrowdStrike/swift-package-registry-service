//
//  CrowdStrike, Inc. CONFIDENTIAL AND PROPRIETARY
//  CrowdStrike, Inc. Copyright (c) 2024. All rights reserved.
//

import Foundation
import HTTPTypes
import OpenAPIRuntime
import Vapor

/// This middleware makes Unified Logging messages for both request and response.
public actor ClientLoggingMiddleware {
    private let logger = Logger(label: "GithubAPIClient")
    private let logHeaders: Bool
    private let bodyLoggingPolicy: BodyLoggingPolicy

    public init(logHeaders: Bool = false, bodyLoggingPolicy: BodyLoggingPolicy = .never) {
        self.logHeaders = logHeaders
        self.bodyLoggingPolicy = bodyLoggingPolicy
    }
}

extension ClientLoggingMiddleware: ClientMiddleware {

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let (requestBodyToLog, requestBodyForNext) = try await bodyLoggingPolicy.process(body)
        log(request, requestBodyToLog)
        do {
            let (response, responseBody) = try await next(request, requestBodyForNext, baseURL)
            let (responseBodyToLog, responseBodyForNext) = try await bodyLoggingPolicy.process(responseBody)
            log(request, response, responseBodyToLog)
            return (response, responseBodyForNext)
        } catch {
            log(request, failedWith: error)
            throw error
        }
    }
}

extension ClientLoggingMiddleware {
    func log(_ request: HTTPRequest, _ requestBody: BodyLoggingPolicy.BodyLog) {
        let path = request.path ?? "<nil>"
        if logHeaders {
            logger.debug("Request: \(request.method) \(path) headers: \(request.headerFields.debugDescription) \(requestBody)")
        } else {
            logger.debug("Request: \(request.method) \(path) \(requestBody)")
        }
    }

    func log(_ request: HTTPRequest, _ response: HTTPResponse, _ responseBody: BodyLoggingPolicy.BodyLog) {
        let path = request.path ?? "<nil>"
        if logHeaders {
            logger.debug("Response: \(request.method) \(path) \(response.status) headers: \(response.headerFields.debugDescription) \(responseBody)")
        } else {
            logger.debug("Response: \(request.method) \(path) \(response.status) \(responseBody)")
        }
    }

    func log(_ request: HTTPRequest, failedWith error: any Error) {
        logger.warning("Request failed. Error: \(error.localizedDescription)")
    }
}

public enum BodyLoggingPolicy: Sendable {
    /// Never log request or response bodies.
    case never
    /// Log request and response bodies that have a known length less than or equal to `maxBytes`.
    case upTo(maxBytes: Int)

    enum BodyLog: Equatable, CustomStringConvertible {
        /// There is no body to log.
        case none
        /// The policy forbids logging the body.
        case redacted
        /// The body was of unknown length.
        case unknownLength
        /// The body exceeds the maximum size for logging allowed by the policy.
        case tooManyBytesToLog(Int64)
        /// The body can be logged.
        case complete(Data)

        var description: String {
            switch self {
            case .none: return ""
            case .redacted: return ""
            case .unknownLength: return "body: <unknown length>"
            case .tooManyBytesToLog(let byteCount): return "body: <\(byteCount) bytes>"
            case .complete(let data): return "body: " + (String(data: data, encoding: .utf8) ?? "nil")
            }
        }
    }

    func process(_ body: HTTPBody?) async throws -> (bodyToLog: BodyLog, bodyForNext: HTTPBody?) {
        switch (body?.length, self) {
        case (.none, _): return (.none, body)
        case (_, .never): return (.redacted, body)
        case (.unknown, _): return (.unknownLength, body)
        case (.known(let length), .upTo(let maxBytesToLog)) where length > maxBytesToLog:
            return (.tooManyBytesToLog(length), body)
        case (.known, .upTo(let maxBytesToLog)):
            // swiftlint:disable:next force_unwrapping
            let bodyData = try await Data(collecting: body!, upTo: maxBytesToLog)
            return (.complete(bodyData), HTTPBody(bodyData))
        }
    }
}

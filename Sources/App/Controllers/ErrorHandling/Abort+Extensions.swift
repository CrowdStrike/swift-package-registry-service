import Vapor

extension Abort {
    init(
        _ status: HTTPResponseStatus,
        headers: HTTPHeaders = [:],
        title: String,
        instance: String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.init(
            status,
            headers: headers,
            reason: title,
            identifier: instance,
            file: file,
            function: function,
            line: line,
            column: column
        )
    }
}

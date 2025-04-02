import Vapor

extension Application {
    var serverURL: String {
        let scheme = http.server.configuration.tlsConfiguration != nil ? "https" : "http"
        let hostname = http.server.configuration.hostname
        let port = http.server.configuration.port
        return "\(scheme)://\(hostname):\(port)"
    }
}

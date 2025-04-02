import AsyncHTTPClient
import NIOHTTP1

extension HTTPClientResponse {
    public static let mock: Self = .init(
        version: .http1_1,
        status: .ok,
        headers: .init([("Content-Type", "application/json")]),
        body: .bytes(
            .init(
                string: """
                    {
                      "releases" : {
                        "0.1.0" : {
                          "url" : "http://127.0.0.1:8080/pointfreeco/swift-overture/0.1.0"
                        },
                        "0.2.0" : {
                          "url" : "http://127.0.0.1:8080/pointfreeco/swift-overture/0.2.0"
                        },
                        "0.3.0" : {
                          "url" : "http://127.0.0.1:8080/pointfreeco/swift-overture/0.3.0"
                        },
                        "0.3.1" : {
                          "url" : "http://127.0.0.1:8080/pointfreeco/swift-overture/0.3.1"
                        },
                        "0.4.0" : {
                          "url" : "http://127.0.0.1:8080/pointfreeco/swift-overture/0.4.0"
                        },
                        "0.5.0" : {
                          "url" : "http://127.0.0.1:8080/pointfreeco/swift-overture/0.5.0"
                        }
                      }
                    }
                    """
            )
        )
    )
}

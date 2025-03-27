import Vapor

extension PackageRegistryController {

    func login(req: Request) async throws -> LoginResponse {
        throw Abort(.notImplemented, title: "Package Registry does not support authentication.")
    }
}

import Vapor

extension PackageRegistryController {
    func createPackageRelease(req: Request) async throws -> PublishResponse {
        // This method is unsupported so we always return an HTTP 405 Method Not Allowed
        throw Abort(.methodNotAllowed, title: "Publishing is not supported in this implementation.")
    }
}

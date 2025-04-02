import Vapor

struct PackageScopeAndName {
    var scope: PackageScope
    var name: PackageName

    var packageId: String {
        "\(scope.value.lowercased()).\(name.value.lowercased())"
    }
}

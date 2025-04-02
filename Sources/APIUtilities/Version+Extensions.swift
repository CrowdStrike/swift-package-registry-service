/// This struct is how Swift Package Manager represents and parses Semantic Versions.
/// It is very important that the package registry server parses tags to Semantic Versions
/// **exactly** how Swift Package Manager does.
///
/// Swift Package Manager makes [this extension](https://github.com/swiftlang/swift-package-manager/blob/main/Sources/Basics/Version%2BExtensions.swift)
/// of the `Version` struct defined in the [swift-tools-support-core](https://github.com/swiftlang/swift-tools-support-core/tree/main)
/// project [here](https://github.com/swiftlang/swift-package-manager/blob/main/Sources/Basics/Version%2BExtensions.swift).
///
/// So since we are trying to make this project parse tags to Semantic Versions **exactly** like
/// Swift Package Manager does, then we include this same extension here.
/// 
extension Version {
    /// Try a version from a git tag.
    ///
    /// - Parameter tag: A version string possibly prepended with "v".
    public init?(tag: String) {
        if tag.first == "v" {
            try? self.init(versionString: String(tag.dropFirst()), usesLenientParsing: true)
        } else {
            try? self.init(versionString: tag, usesLenientParsing: true)
        }
    }
}

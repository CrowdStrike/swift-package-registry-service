public struct SemanticVersion: Equatable, Sendable {
    public var major: Int
    public var minor: Int
    public var patch: Int
    public var prerelease: [String]
    public var metadata: [String]

    public init(_ major: Int, _ minor: Int, _ patch: Int, prerelease: [String] = [], metadata: [String] = []) {
        precondition(major >= 0 && minor >= 0 && patch >= 0, "negative versioning is invalid")
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.metadata = metadata
    }
}

extension SemanticVersion: Comparable {
    @inlinable
    public static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        return !(lhs < rhs) && !(lhs > rhs)
    }

    public static func < (_ lhs: Self, _ rhs: Self) -> Bool {
        let lhsVersion: [Int] = [lhs.major, lhs.minor, lhs.patch]
        let rhsVersion: [Int] = [rhs.major, rhs.minor, rhs.patch]

        guard lhsVersion == rhsVersion else {
            return lhsVersion.lexicographicallyPrecedes(rhsVersion)
        }

        // Non-pre-release lhs >= potentially pre-release rhs
        guard lhs.prerelease.count > 0 else { return false }
        // Pre-release lhs < non-pre-release rhs
        guard rhs.prerelease.count > 0 else { return true }

        for (lhs, rhs) in zip(lhs.prerelease, rhs.prerelease) {
            if lhs == rhs { continue }

            // Check if either of the 2 pre-release components is numeric.
            switch (Int(lhs), Int(rhs)) {
            case let (.some(lhs), .some(rhs)):
                return lhs < rhs
            case (.some(_), .none):
                // numeric pre-release < non-numeric pre-releaes
                return true
            case (.none, .some(_)):
                // non-numeric pre-release > numeric pre-release
                return false
            case (.none, .none):
                return lhs < rhs
            }
        }

        return lhs.prerelease.count < rhs.prerelease.count
    }
}

extension SemanticVersion: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(major)
        hasher.combine(minor)
        hasher.combine(patch)
        hasher.combine(prerelease)
    }
}

extension SemanticVersion: CustomStringConvertible {

    public var description: String {
        var version: String = "\(major).\(minor).\(patch)"
        if !prerelease.isEmpty {
            version += "-\(prerelease.joined(separator: "."))"
        }
        if !metadata.isEmpty {
            version += "+\(metadata.joined(separator: "."))"
        }
        return version
    }
}

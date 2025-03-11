import Vapor

struct PackageName {
    var value: String
}

extension PackageName: LosslessStringConvertible {
    var description: String { value }

    init?(_ description: String) {
        value = description.hasSuffix(".json") ? String(description.dropLast(5)) : description
    }

    var isValid: Bool {
        do {
            let regex = try Regex(#"\A[a-zA-Z0-9](?:[a-zA-Z0-9]|[-_](?=[a-zA-Z0-9])){0,99}\z"#)
            let result = try regex.wholeMatch(in: value)
            return result != nil
        } catch {
            Logger(label: "PackageScope").error("Regex error: \(error)")
            return false
        }
    }
}

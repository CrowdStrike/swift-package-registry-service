import Vapor

struct PackageScope {
    var value: String
}

extension PackageScope: LosslessStringConvertible {
    var description: String { value }

    init?(_ description: String) {
        value = description
    }

    var isValid: Bool {
        do {
            let regex = try Regex(#"\A[a-zA-Z0-9](?:[a-zA-Z0-9]|-(?=[a-zA-Z0-9])){0,38}\z"#)
            let result = try regex.wholeMatch(in: value)
            return result != nil
        } catch {
            Logger(label: "PackageScope").error("Regex error: \(error)")
            return false
        }
    }
}

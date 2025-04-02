import Foundation

extension JSONEncoder.OutputFormatting {
    #if DEBUG
    public static let `default`: Self = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    #else
    public static let `default`: Self = [.sortedKeys, .withoutEscapingSlashes]
    #endif
}

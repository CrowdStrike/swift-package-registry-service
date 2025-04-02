import RegexBuilder

public struct SwiftToolsVersionParser {
    let swiftToolsRegex: Regex<(Substring, Substring)>

    public func parse(_ input: String) throws -> String? {
        guard let match = try swiftToolsRegex.firstMatch(in: input) else {
            return nil
        }
        return String(match.1)
    }

    public init() {
        let digitsWithNoLeadingZeroRegex = Regex {
            ("1"..."9")
            ZeroOrMore(.digit)
        }

        let numericIdentifierRegex = Regex {
            ChoiceOf {
                "0"
                digitsWithNoLeadingZeroRegex
            }
        }

        let alphaWithHyphen = CharacterClass(
            .anyOf("-"),
            ("a"..."z"),
            ("A"..."Z")
        )

        let alphaNumericWithHyphen = CharacterClass(
            .anyOf("-"),
            ("0"..."9"),
            ("a"..."z"),
            ("A"..."Z")
        )

        let prereleaseIdentifierRegex = Regex {
            ZeroOrMore(.digit)
            alphaWithHyphen
            ZeroOrMore {
                alphaNumericWithHyphen
            }
        }

        let preReleaseChoiceRegex = Regex {
            ChoiceOf {
                "0"
                digitsWithNoLeadingZeroRegex
                prereleaseIdentifierRegex
            }
        }

        let preReleaseRegex = Regex {
            preReleaseChoiceRegex
            ZeroOrMore {
                "."
                preReleaseChoiceRegex
            }
        }

        let buildRegex = Regex {
            OneOrMore {
                alphaNumericWithHyphen
            }
            ZeroOrMore {
                "."
                OneOrMore {
                    alphaNumericWithHyphen
                }
            }
        }

        self.swiftToolsRegex = Regex {
            Anchor.startOfSubject

            "//"

            ZeroOrMore(.whitespace)

            "swift-tools-version:"

            ZeroOrMore(.whitespace)

            Capture {
                numericIdentifierRegex
                "."
                numericIdentifierRegex
                Optionally {
                    "."
                    numericIdentifierRegex
                }
                Optionally {
                    "-"
                    preReleaseRegex
                }
                Optionally {
                    "+"
                    buildRegex
                }
            }

            Optionally {
                ";"
            }
        }
    }
}

import RegexBuilder

public struct SemanticVersionParser {
    let semVerRegex: Regex<(Substring, Substring, Substring, Substring, Substring?, Substring?)>

    public func parse(_ input: String) throws -> SemanticVersion? {
        guard let wholeMatch = try semVerRegex.wholeMatch(in: input) else {
            return nil
        }
        return SemanticVersion(
            wholeMatch.1,
            wholeMatch.2,
            wholeMatch.3,
            wholeMatch.4,
            wholeMatch.5
        )
    }

    public func semVerString(from input: String) throws -> String? {
        guard let firstMatch = try semVerRegex.firstMatch(in: input) else {
            return nil
        }
        return String(input[firstMatch.range])
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


        self.semVerRegex = Regex {
            Capture {
                numericIdentifierRegex
            }
            "."
            Capture {
                numericIdentifierRegex
            }
            "."
            Capture {
                numericIdentifierRegex
            }
            Optionally {
                "-"
                Capture {
                    preReleaseRegex
                }
            }
            Optionally {
                "+"
                Capture {
                    buildRegex
                }
            }
        }
    }
}

extension SemanticVersion {

    init?(
        _ major: Substring,
        _ minor: Substring,
        _ patch: Substring,
        _ prerelease: Substring?,
        _ build: Substring?
    ) {
        guard
            let majorInt = Int(major),
            let minorInt = Int(minor),
            let patchInt = Int(patch)
        else {
            return nil
        }
        self.init(
            majorInt,
            minorInt,
            patchInt,
            prerelease: prerelease.map { $0.split(separator: ".").map { String($0) } } ?? [],
            metadata: build.map { $0.split(separator: ".").map { String($0) } } ?? []
        )
    }
}

import RegexBuilder

public struct GithubURL: Equatable, Sendable {
    public var scope: String
    public var name: String
    public var urlType: URLType

    public enum URLType: String, Equatable, Sendable {
        case https
        case ssh
    }

    public init?(urlString: String) {
        let pathComponent = Regex {
            OneOrMore(.word.union(.anyOf("-~!$&\"*+,;=:")))
        }

        let httpsURLRegex = Regex {
            "https://github.com/"

            Capture {
                pathComponent
            }

            "/"

            Capture {
                pathComponent
            }

            Optionally {
                ".git"
            }
        }

        let sshURLRegex = Regex {
            "git@github.com:"

            Capture {
                pathComponent
            }

            "/"

            Capture {
                pathComponent
            }

            ".git"
        }

        do {
            if let httpsMatch = try httpsURLRegex.wholeMatch(in: urlString) {
                self.scope = String(httpsMatch.output.1)
                self.name = String(httpsMatch.output.2)
                self.urlType = .https
            } else if let sshMatch = try sshURLRegex.wholeMatch(in: urlString) {
                self.scope = String(sshMatch.output.1)
                self.name = String(sshMatch.output.2)
                self.urlType = .ssh
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}

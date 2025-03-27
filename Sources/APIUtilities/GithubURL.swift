import RegexBuilder

public struct GithubURLParser {
    let htmlURLRegex: Regex<(Substring, Substring, Substring)>
    let cloneURLRegex: Regex<(Substring, Substring, Substring)>
    let sshURLRegex: Regex<(Substring, Substring, Substring)>

    public init() {
        let pathComponent = Regex {
            OneOrMore(.word.union(.anyOf("-~!$&\"*+,;=:")))
        }

        let scopeAndNameRegex = Regex {
            Capture {
                pathComponent
            }

            "/"

            Capture {
                pathComponent
            }
        }

        let htmlURLRegex = Regex {
            "https://github.com/"

            scopeAndNameRegex
        }

        let cloneURLRegex = Regex {
            htmlURLRegex

            ".git"
        }

        let sshURLRegex = Regex {
            "git@github.com:"

            scopeAndNameRegex

            ".git"
        }

        self.htmlURLRegex = htmlURLRegex
        self.cloneURLRegex = cloneURLRegex
        self.sshURLRegex = sshURLRegex
    }

    public func parse(urlString: String) -> GithubURL? {
        do {
            if let cloneMatch = try cloneURLRegex.wholeMatch(in: urlString) {
                let scope = String(cloneMatch.output.1)
                let name = String(cloneMatch.output.2)
                return GithubURL(scope: scope, name: name, urlType: .clone)
            } else if let htmlMatch = try htmlURLRegex.wholeMatch(in: urlString) {
                let scope = String(htmlMatch.output.1)
                let name = String(htmlMatch.output.2)
                return GithubURL(scope: scope, name: name, urlType: .html)
            } else if let sshMatch = try sshURLRegex.wholeMatch(in: urlString) {
                let scope = String(sshMatch.output.1)
                let name = String(sshMatch.output.2)
                return GithubURL(scope: scope, name: name, urlType: .ssh)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}

public struct GithubURL: Hashable, Sendable {
    public var scope: String
    public var name: String
    public var urlType: URLType

    public enum URLType: String, Hashable, Sendable {
        case html
        case clone
        case ssh
    }

    public init(scope: String, name: String, urlType: URLType) {
        self.scope = scope
        self.name = name
        self.urlType = urlType
    }

    var urlString: String {
        switch urlType {
        case .html:
            "https://github.com/\(scope)/\(name)"
        case .clone:
            "https://github.com/\(scope)/\(name).git"
        case .ssh:
            "git@github.com:\(scope)/\(name).git"
        }
    }
}

extension GithubURL: CustomStringConvertible {

    public var description: String { urlString }
}

extension GithubURL {

    public init?(urlString: String) {
        let parser = GithubURLParser()
        if let url = parser.parse(urlString: urlString) {
            self = url
        } else {
            return nil
        }
    }
}

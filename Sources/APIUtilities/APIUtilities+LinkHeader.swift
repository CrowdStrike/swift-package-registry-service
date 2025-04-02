import Foundation
import Vapor

extension APIUtilities {

    public struct PageInfo {
        public var perPage: Int?
        public var page: Int?

        public init(perPage: Int? = nil, page: Int? = nil) {
            self.perPage = perPage
            self.page = page
        }
    }

    public static func nextPage(forLinkHeader linkHeader: String?) -> PageInfo? {
        guard let linkHeader else { return nil }
        // Parse the link header and look for a link
        // which is a "next" relation.
        let httpHeaders = HTTPHeaders([("Link", linkHeader)])
        guard
            let links = httpHeaders.links,
            let nextLink = links.first(where: { $0.relation == .next })
        else {
            return nil
        }

        // Now parse the next URL and pull out the "per_page" and "page" query parameters
        return pageInfo(from: nextLink.uri)
    }

    public static func listPackageReleasesLinkHeader(
        from linkHeader: String?,
        serverURLString: String,
        owner: String,
        repo: String
    ) -> String? {
        guard let linkHeader else { return nil }
        // Parse the link header
        var httpHeaders = HTTPHeaders([("Link", linkHeader)])
        guard let links = httpHeaders.links else {
            return linkHeader
        }
        let updatedLinks = links.map {
            $0.withUpdatedURI(
                listPackageReleasesURL(
                    serverURLString: serverURLString,
                    owner: owner,
                    repo: repo,
                    pageInfo: pageInfo(from: $0.uri)
                )
            )
        }
        httpHeaders.links = updatedLinks
        let renderedLinks = httpHeaders["Link"]
        guard !renderedLinks.isEmpty else {
            return linkHeader
        }
        return renderedLinks.joined(separator: ", ")
    }

    static func pageInfo(from linkHeaderURLString: String) -> PageInfo? {
        guard
            let urlComponents = URLComponents(string: linkHeaderURLString),
            let queryItems = urlComponents.queryItems
        else {
            return nil
        }
        return PageInfo(
            perPage: queryItems.first(where: { $0.name == "per_page" })?.value.flatMap(Int.init),
            page: queryItems.first(where: { $0.name == "page" })?.value.flatMap(Int.init)
        )
    }

    static func listPackageReleasesURL(
        serverURLString: String,
        owner: String,
        repo: String,
        pageInfo: PageInfo?
    ) -> String {
        var urlString = "\(serverURLString)/\(owner)/\(repo)"
        if let pageInfo {
            var queryParams = [String]()
            if let perPage = pageInfo.perPage {
                queryParams.append("per_page=\(perPage)")
            }
            if let page = pageInfo.page {
                queryParams.append("page=\(page)")
            }
            if !queryParams.isEmpty {
                let allQueryParams = queryParams.joined(separator: "&")
                urlString += "?\(allQueryParams)"
            }
        }
        return urlString
    }
}

extension HTTPHeaders.Link {
    func withUpdatedURI(_ uri: String) -> Self {
        .init(uri: uri, relation: relation, attributes: attributes)
    }
}

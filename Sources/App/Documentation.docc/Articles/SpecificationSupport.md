# Specification Support

See the status of each feature in the Swift Package Registry Service specification.

## Feature Table

The following table references the [Swift Package Registry Service Specification](https://github.com/swiftlang/swift-package-manager/blob/main/Documentation/PackageRegistry/Registry.md).
For each **server** feature listed in the Specification, the table says if this feature is supported in this implementation.
This table will change as more features in the server are implemented.

| Section | Specification | Support |
| ------- | ------------- | ------- |
| 3.2     | Server MAY require authentication | ✅ No user-level authentication to this SPR Service is required. You set the `GITHUB_API_TOKEN` environment variable to access the Github API. |
| 3.2     | A server SHOULD respond with a status code of 401 (Unauthorized) if a client sends a request to an endpoint that requires authentication without providing credentials. | ✅ No user-level authentication to this SPR Service is required. You set the `GITHUB_API_TOKEN` environment variable to access the Github API. |
| 3.2     | A server MAY respond with a status code of 404 (Not Found) or 403 (Forbidden) when a client provides valid credentials but isn't authorized to access the requested resource. | ✅ No user-level authentication to this SPR Service is required. You set the `GITHUB_API_TOKEN` environment variable to access the Github API. |
| 3.2     | A server MAY use any authentication model of its choosing. | ✅ No user-level authentication to this SPR Service is required. You set the `GITHUB_API_TOKEN` environment variable to access the Github API. |
| 3.3     | Server MUST communicate any errors to the client using "problem details" objects. |  ✅ |
| 3.4     | Server MAY limit the number of requests made by a client by responding with a status code of `429 Too Many Requests`  |   ✅ |
| 3.5     | Server MUST set the `Content-Type` header field with the corresponding content type of the response.  |   ✅ |
| 3.5     | Server MUST set the `Content-Version` header field with the API version number of the response.   |  ✅ |
| 3.5     | If a client sends a request without an `Accept` header, a server MAY either respond with a status code of 400 Bad Request or process the request using an API version that it chooses, making sure to set the `Content-Type` and `Content-Version` headers accordingly. |  ✅ If no `Accept` header is specified, then the request is processed assuming content version 1. |
| 3.5     | If a client sends a request with an `Accept` header that specifies an unknown or invalid API version, a server SHOULD respond with a status code of `400 Bad Request`. | ✅ |
| 3.5     | If a client sends a request with an `Accept` header that specifies a valid but unsupported API version, a server SHOULD respond with a status code of `415 Unsupported Media Type`. |  ✅ |
| 3.6.1   | Package scopes are limited to 39 characters. | ✅ |
| 3.6.1   | Package scopes conform to the regular expression `\A[a-zA-Z0-9](?:[a-zA-Z0-9]\|-(?=[a-zA-Z0-9])){0,38}\z`. | ✅ |
| 3.6.1   | Package scopes are case-insensitive.  | ✅ |
| 3.6.2   | Package names are limited to 100 characters. | ✅ |
| 3.6.2   | Package names conform to the regular expression `\A[a-zA-Z0-9](?:[a-zA-Z0-9]\|[-_](?=[a-zA-Z0-9])){0,99}\z`. | ✅ |
| 3.6.2   | Package names are case-insensitive.   | ✅ |
| 4       | A server SHOULD also respond to `HEAD` requests for each of the specified endpoints. | ❌ |
| 4       | A server MAY respond to an `OPTIONS` request with a `Link` header containing an entry for the service-doc relation type with a link to this document, and an entry for the service-desc relation type with a link to the OpenAPI specification. | ❌ |
| 4.1     | If a package is found at the requested location, a server SHOULD respond with a status code of `200 OK` and the `Content-Type` header `application/json`. Otherwise, a server SHOULD respond with a status code of `404 Not Found`. |  ✅ |
| 4.1     | A server SHOULD respond with a JSON document containing the releases for the requested package. |  ✅ |
| 4.1     | A server SHOULD communicate the unavailability of a package release using a "problem details" object. |  ✅ |
| 4.1     | A server SHOULD respond with a link to the highest precedence published release of the package if one exists, using a `Link` header field with a `latest-version` relation. | ❌ |
| 4.1     | A server SHOULD list releases in order of precedence, starting with the highest precedence version. | ❌ |
| 4.1     | A server MAY include a `Link` entry with the canonical relation type that locates the source repository of the package. | ❌ |
| 4.1     | A server MAY include one or more `Link` entries with the `alternate` relation type for other source repository locations. | ❌ |
| 4.1     | A server MAY paginate results by responding with a `Link` header.  |  ✅ CLIENT_SUPPORTS_PAGINATION environment variable should be set to `true` to enable pagination. |
| 4.1     | A server MAY respond with additional `Link` entries, such as one with a payment relation for sponsoring a package maintainer.  | ❌ |
| 4.2     | If a release is found at the requested location, a server SHOULD respond with a status code of `200 OK` and the `Content-Type` header `application/json`. Otherwise, a server SHOULD respond with a status code of `404 Not Found`.  |  ✅ |
| 4.2     | A server SHOULD respond with a `Link` header containing `latest-version`, `successor-version`, and `predecessor-version`.  | ❌ |
| 4.2     | The link with `latest-version` MAY correspond to the requested release.  | ❌ |
| 4.2.1   | Signed packages.   | ❌ |
| 4.2.1   | A resource object SHOULD have one of the following combinations of name and type values: `name=source-archive` and `type=application/zip`. | ✅ |
| 4.2.1   | A release MUST NOT have more than a single resource object with a given combination of name and type values. | ✅ |
| 4.2.2   | A server MAY allow and/or populate additional metadata by expanding the schema. The metadata key in the "fetch information about a package release" API response will hold the user-provided as well as the server populated metadata. | ❌ |
| 4.3     | If a release is found at the requested location, a server SHOULD respond with a status code of `200 OK` and the `Content-Type` header `text/x-swift`. Otherwise, a server SHOULD respond with a status code of `404 Not Found`.  |  ✅ |
| 4.3     | A server SHOULD respond with a `Content-Length` header set to the size of the manifest in bytes. | ✅ |
| 4.3     | A server SHOULD respond with a `Content-Disposition` header set to attachment with a filename parameter equal to the name of the manifest file (for example, "Package.swift").  | ✅ |
| 4.3     | A server MAY omit the `Content-Version` header since the response content (i.e., the manifest) SHOULD NOT change across different API versions. |  ✅ |
| 4.3     | A server MUST include a `Link` header field with a value for each version-specific package manifest file in the release's source archive. |  ✅ |
| 4.3     | Each link value SHOULD have the `alternate` relation type.  |  ✅ |
| 4.3     | Each link value SHOULD have `filename` attribute set to the version-specific package manifest filename.  |  ✅ |
| 4.3     | Each link value SHOULD have a `swift-tools-version` attribute set to the Swift tools version specified by the package manifest file.  | ✅ |
| 4.3.1   | If the package includes a file named Package@swift-{swift-version}.swift, the server SHOULD respond with a status code of `200 OK` and the content of that file in the response body. |  ✅ |
| 4.3.1   | Otherwise, the server SHOULD respond with a status code of `303 See Other` and redirect to the unqualified Package.swift resource. |  ✅ |
| 4.4     | If a release is found at the requested location, a server SHOULD respond with a status code of `200 OK` and the `Content-Type` header `application/zip`. Otherwise, a server SHOULD respond with a status code of `404 Not Found`. |  ✅ |
| 4.4     | A server MUST respond with a `Content-Length` header set to the size of the archive in bytes. | ✅ |
| 4.4     | A server MAY respond with a `Digest` header containing a cryptographic digest of the source archive. | ❌ |
| 4.4     | A server SHOULD respond with a `Content-Disposition` header set to attachment with a filename parameter equal to the name of the package followed by a hyphen (-), the version number, and file extension (for example, "LinkedList-1.1.1.zip").  | ✅ |
| 4.4     | A server MAY omit the `Content-Version` header since the response content (i.e., the source archive) SHOULD NOT change across different API versions. |  ✅ |
| 4.4     | It is RECOMMENDED for clients and servers to support range requests.  | ❌ |
| 4.4     | If a release is signed, a server MUST include `X-Swift-Package-Signature-Format` and `X-Swift-Package-Signature` headers in the response. | ❌ |
| 4.4.2   | A server MAY specify mirrors or multiple download locations using `Link` header fields with a `duplicate` relation.  | ❌ |
| 4.4.2   | A server MAY respond with a status code of `303 See Other` to redirect the client to download the source archive from another host.  | ❌ |
| 4.5     | When no url parameter is specified, a server SHOULD respond with a status code of `400 Bad Request`.  |  ✅ |
| 4.5     | If one or more package identifiers are associated with the specified URL, a server SHOULD respond with a status code of `200 OK` and the `Content-Type` header `application/json`. Otherwise, a server SHOULD respond with a status code of `404 Not Found`.   |  ✅ |
| 4.5     | A server SHOULD respond with a JSON document containing the package identifiers for the specified URL.  |  ✅ |
| 4.5     | The response body MUST contain an array of package identifier strings nested at a top-level identifiers key.  |  ✅ |
| 4.5     | A server SHOULD validate the package author's ownership claim on the corresponding repository.  |  ✅ |
| 4.6     | Create a Package Release | ❌ Publishing is not supported. |
| 4.6     | Support for this endpoint is OPTIONAL. A server SHOULD indicate that publishing isn't supported by responding with a status code of 405 (Method Not Allowed).  |  ✅ |

# Swift Package Registry Service 

This is an implementation of the Swift Package Registry Service which proxies the Github API.

## Building and Running the Service

### Github Personal Access Token

Many methods of the [Github API](https://docs.github.com/en/rest?apiVersion=2022-11-28) is accessible without authentication.
However, the [rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28)
are much lower. Therefore, it is advisable to provide the service with a
[Github Personal Access Token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
to authenticate with the Github API.

### Using Xcode

1. In Xcode, do File/Open and open the `Package.swift` in this repository. Allow package resolution to finish.
2. Make sure that the target build device is "My Mac".
3. Click on the `swift-package-registry-service` scheme and choose "Edit Scheme".
4. Choose the "Run" action in the left-hand pane.
5. Choose the "Arguments" tab in the top-center.
6. In the "Environment Variables" section, click the "+" button.
7. Name the new environment variable `GITHUB_API_TOKEN`.
8. Set the value of `GITHUB_API_TOKEN` to be your Github Personal Access Token.
9. Choose the "Options" tab in the top-center.
10. Select the checkbox beside "Use custom working directory" and choose the directory where you cloned the repository.
11. Choose Close in the bottom right to finish editing the `swift-package-registry-service` scheme.
12. Click the Play button in the upper-left to Build and Run.

Once the build has succeeded and the server started, you should see something like this in the Xcode console:

```
[ NOTICE ] Server started on http://127.0.0.1:8080
```

If you see a message something like this in the Xcode console:

```
[ WARNING ] No custom working directory set for this scheme, using /Users/ehyche/Library/Developer/Xcode/DerivedData/swift-package-registry-service-github-bwqdugfplzkkyueszneqimmdhxqo/Build/Products/Debug (Vapor/DirectoryConfiguration.swift:57)
```

then you have forgotten to set the Custom Working Directory in Step 10 above.

### Using Command Line

If you want to build and run using the `swift` command line, then do the following:

```
git clone https://github.com/CrowdStrike/swift-package-registry-service.git
cd swift-package-registry-service
export GITHUB_API_TOKEN="<your-Github-PAT>"
swift run
```

You should see something like:

```
$ swift run
Building for debugging...
...
Build of product 'App' complete! (25.07s)
[ NOTICE ] Server started on http://127.0.0.1:8080
```

## Configuring Swift Package Manager to use the package registry

You will also need to configure Swift Package Manager to be aware of the package registry server:

```
swift package-registry set --global --allow-insecure-http http://127.0.0.1:8080
```

This will place this information in `~/.swiftpm/configuration/registries.json` and will
be global for all packages and projects on this machine.

On the other hand, if you only want to configure a single package or project, then leave
out the `--global` flag above:

```
cd ~/src/some-project-to-configure
swift package-registry set --allow-insecure-http http://127.0.0.1:8080
```

then this will place this information in `~/src/some-project-to-configure/.swiftpm/configuration/registries.json`
and thus will only apply to `some-project-to-configure`.

## Changing your Package.swift to use package identifiers

Normally, we are used to adding Github dependencies to a package manifest like this:

```
let package = Package(
    name: "MyPackage",
    ...,
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
    ],
    targets: [
        .target(
            name: "MyTarget",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Collections", package: "swift-collections"),
            ]
        ),
    ],
    ...,
)
```

However, if you want to use the package registry, then we would use package identifiers instead
(in both the package-level and target-level dependencies):

```
let package = Package(
    name: "MyPackage",
    ...,
    dependencies: [
        .package(id: "apple.swift-async-algorithms", from: "1.0.0"),
        .package(id: "apple.swift-collections", from: "1.1.4"),
    ],
    targets: [
        .target(
            name: "MyTarget",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "apple.swift-async-algorithms"),
                .product(name: "Collections", package: "apple.swift-collections"),
            ]
        ),
    ],
    ...,
)
```

## Handling transitive dependencies

In the `MyPackage` example above, have **direct** dependency upon `swift-async-algorithms` and `swift-collections`.
However, if you look at the `Package.swift` for `swift-async-algorithms`:

```
let package = Package(
  name: "swift-async-algorithms",
  ...,
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.4"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
  ],
  ...,
```

then we see that `swift-async-algorithms` depends on `swift-collections` and `swift-docc-plugin`.
So `MyPackage` has a **transitive** dependency upon `swift-collections` and `swift-docc-plugin`. Therefore,
`MyPackage` has the following dependencies:

* A **direct** dependency upon `swift-async-algorithms`.
* Both a **direct** AND a **transitive** dependency upon `swift-collections`.
* A **transitive** dependency upon `swift-docc-plugin`.

For the `swift-collection` dependency:

* Our **direct** dependency is via a package identifier
* Our **transitive** dependency is via a Github URL.

So the question becomes: how should Swift Package Manager treat the two different `swift-collection` dependencies?

As explained [here](https://github.com/swiftlang/swift-package-manager/blob/main/Documentation/PackageRegistry/PackageRegistryUsage.md#using-registry-for-source-control-dependencies),
we have three choices:

- **Option 1** Treat "apple.swift-collections" and "https://github.com/apple/swift-collections.git" as
  completely different dependencies. The "apple.swift-collections" dependency will be resolved via the package registry, and "https://github.com/apple/swift-collections.git" will be resolved by cloning the respository.
  **Note that this option will likely result in duplicate symbol errors**, since the identical library
  is included twice.
- **Option 2**. Still fetch "apple.swift-collections" from the registry and clone
  "https://github.com/apple/swift-collections.git", but use the registry "lookup identifier" endpoint
  to determine if they are, in fact, the same dependency.
- **Option 3**. Use to registry's "lookup identifier" endpoint to determine whether or not
   "https://github.com/apple/swift-collections.git" is, in fact, the same as "apple.swift-collections".
   If it is, then replace all usages of "https://github.com/apple/swift-collections.git" with "apple.swift-collections" and use the registry whenever possible.

## Specifying transitive dependency policy via command line

If we are building using the `swift` command line, then we specify the above transitive dependency handling options like this:

1. Option 1: `--disable-scm-to-registry-transformation`
2. Option 2: `--use-registry-identity-for-scm`
3. Option 3: `--replace-scm-with-registry`

For example:

```
cd ~/src/my-package
swift build --replace-scm-with-registry
```

## Specifying transitive dependency policy via xcodebuild

If you are building using `xcodebuild`, then you specify the transitive dependency policy via
the `-packageDependencySCMToRegistryTransformation` option:

1. Option 1: `-packageDependencySCMToRegistryTransformation none`
2. Option 2: `-packageDependencySCMToRegistryTransformation useRegistryIdentity`
3. Option 3: `-packageDependencySCMToRegistryTransformation useRegistryIdentityAndSources`

Side note: if building via `xcodebuild` you can also specify the default registry URL via
the `-defaultPackageRegistryURL` option:

```
xcodebuild -defaultPackageRegistryURL "http://127.0.0.1:8080/"
```

## Specification Support

The following table shows the current state of the implementation, according to the
[Swift Package Registry Service specification](https://github.com/swiftlang/swift-package-manager/blob/main/Documentation/PackageRegistry/Registry.md).

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

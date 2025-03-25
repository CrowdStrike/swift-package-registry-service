# Architecture

This article describes the architecture of the Swift Package Registry Service.

## Architecture Diagram

Visually, the architecture can be described as:

![High-Level Architecture](../Resources/HighLevelArchitecture.png)

Each of the components above are the following:

* Checksum Client. This can be found in the `ChecksumClient` module, and is an abstraction of a SHA256 checksum.
* GithubAPIClient. This is an abstraction of the minimal set of Github API endpoints that we need. The public
  API can be found in the `GithubAPIClient` module, and the implementation can be found in the `GithubAPIClientImpl` module.
* Github OpenAPI Codegen. This can be found in the `GithubOpenAPI` module. It uses the [swift-openapi-generator](https://github.com/apple/swift-openapi-generator)
  Swift Package Manager plugin to generate code from the Github API.
* HTTP Stream Client. This can be found in the `HTTPStreamClient` module, and is an abstraction of an HTTP client.
* Persistence Client. This is a client for reading and writing cached data to/from the disk. It can
  be found in the `PersistenceClient` module.
* File Client. This is an abstraction for a file system, and can be found in the `FileClient` module.

For all of our clients, we use the [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) style of clients.

## Swift Package Registry Service endpoints

As described [here](https://github.com/swiftlang/swift-package-manager/blob/main/Documentation/PackageRegistry/Registry.md#4-endpoints),
a Swift Package Registry Service must implement 6 endpoints:

1. List Package Releases (`GET /{scope}/{name}`)
2. Fetch Release Metadata (`GET /{scope}/{name}/{version}`)
3. Fetch Manifest (`GET /{scope}/{name}/{version}/Package.swift`)
4. Download Source Archive (`GET /{scope}/{name}/{version}.zip`)
5. Lookup Package Identifiers (`GET /identifiers?url=`)
6. Create Package Release (`PUT /{scope}/{name}/{version}`)

However, the Create Package Release endpoint is optional. From the spec:

```
Support for this endpoint is OPTIONAL. A server SHOULD indicate that publishing isn't supported by responding with a status code of 405 (Method Not Allowed).
```

Since we are only interested in our service being a read-only service, then we do not support publishing, and thus the Create Package Release
endpoint always returns `405 Method Not Allowed`.

The sections which follow provide more detail into the implementation of each of the endpoints.

## List Package Releases implementation

The List Packages Releases (`GET /{scope}/{name}`) endpoint is implemented as follows:

1. Do checks to validate the input parameters (package scope, package name, and Accept header).
2. Check the memory cache for tag information for this package:
   - If there is cached tag information and it is less than 5 minutes old, then use it to construct the response.
   - Otherwise, we proceed to step 3 to refresh the memory-cached tag information.
3. Attempt to read the cached tag information from the disk cache. If the age
   of the disk-cached tag information is less than 30 minutes old, then use to to construct
   the response. Otherwise, proceed to step 4 to refresh the disk-cached tag information.
4. If we have at least one tag in the disk-cache, then call the Github API
   [List Repository Tags](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-tags)
   endpoint to fetch the latest tag. If the latest tag was present in the disk cache,
   then we know the disk cache is up-to-date and we use the tag information
   in the disk cache to construct the response. Otherwise, we proceed to step 5.
5. Next, using the same 
   [List Repository Tags](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-tags)
   endpoint, we fetch all of the tags for this repository, one page at a time.
## Fetch Release Metadata Implementation


## Fetch Manifest Implementation


## Download Source Archive Implementation


## Lookup Package Identifiers Implementation


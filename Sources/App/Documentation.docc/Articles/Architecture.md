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

## Github API

We can implement a Swift Package Registry Service by using these four operations in the Github API:

1. [List Repository Tags](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-tags)
2. [Get A Release By Tag Name](https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#get-a-release-by-tag-name)
3. [Get Repository Content](https://docs.github.com/en/rest/repos/contents?apiVersion=2022-11-28#get-repository-content)
4. [Get Repository](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#get-a-repository)

### List Repository Tags

This endpoint in the Github API provides a paginated list of tags for a repository:

```
$ curl -H "X-GitHub-Api-Version: 2022-11-28" \
     -H "Accept: application/vnd.github+json" \
     -H "Authorization: Bearer <your-PAT>" \
     --no-progress-meter \
     https://api.github.com/repos/pointfreeco/swift-overture/tags
[
  {
    "name": "0.5.0",
    "zipball_url": "https://api.github.com/repos/pointfreeco/swift-overture/zipball/refs/tags/0.5.0",
    "tarball_url": "https://api.github.com/repos/pointfreeco/swift-overture/tarball/refs/tags/0.5.0",
    "commit": {
      "sha": "7977acd7597f413717058acc1e080731249a1d7e",
      "url": "https://api.github.com/repos/pointfreeco/swift-overture/commits/7977acd7597f413717058acc1e080731249a1d7e"
    },
    "node_id": "MDM6UmVmMTI4NzkxMTcwOnJlZnMvdGFncy8wLjUuMA=="
  },
  ...,
  {
    "name": "0.1.0",
    "zipball_url": "https://api.github.com/repos/pointfreeco/swift-overture/zipball/refs/tags/0.1.0",
    "tarball_url": "https://api.github.com/repos/pointfreeco/swift-overture/tarball/refs/tags/0.1.0",
    "commit": {
      "sha": "b907805523ca75a0c9fdaaf1bdf81b3fe3360ac7",
      "url": "https://api.github.com/repos/pointfreeco/swift-overture/commits/b907805523ca75a0c9fdaaf1bdf81b3fe3360ac7"
    },
    "node_id": "MDM6UmVmMTI4NzkxMTcwOnJlZnMvdGFncy8wLjEuMA=="
  }
]
```

Notice the information we need in each tag dictionary is: a) the tag `name`; and b) the `zipball_url`, which is an URL to download
the source archive for that tag.

#### Tags vs Semantic Versions

Notice that the tags listed above are simply git tags. They can be whatever the repository
author wants them to be: "1.2.3", "v1.2.3", "version_1.2.3", or whatever.

The [Swift Package Registry Service Specification](https://github.com/swiftlang/swift-package-manager/blob/main/Documentation/PackageRegistry/Registry.md#2-definitions),
on the other hand, specifies that its versions MUST be semantic verions, as defined by
the [Semantic Versioning 2.0.0 spec](https://semver.org/).

### Get A Release By Tag Name

### Get Repository Content

### Get Repository

The sections which follow provide more detail into the implementation of each of the endpoints.

## List Package Releases implementation


## Fetch Release Metadata Implementation


## Fetch Manifest Implementation


## Download Source Archive Implementation


## Lookup Package Identifiers Implementation


# ToDoList

This is a list of known improvement tasks.

## Make Download Source Archive response more memory-efficient

Currently, in the Download Source Archive operation, we read the entire source archive
into memory, and then return that entire memory buffer in the response. Instead
of reading the entire source archive into memory, we should stream it to the response
so that only one chunk at a time is read into memory.


## Make Fetch Manifest response more memory-efficient

Currently, in the Fetch Manifest operation, we read the entire manifest into memory,
and then return that entire memory buffer in the response. Instead of reading
the entire manifest into memory, we should stream it to the response
so that only one chunk at a time is read into memory.

## Move `manifests.json` into a DB table

Currently, we store the repository manifests information in a directory-specific
`manifests.json` file. For example, the [swift-clocks](https://github.com/pointfreeco/swift-clocks)
repository has two package manifests: an [unversioned Package.swift manifest](https://github.com/pointfreeco/swift-clocks/blob/main/Package.swift)
and a [swift-6.0-specific manifest](https://github.com/pointfreeco/swift-clocks/blob/main/Package%40swift-6.0.swift).
We currently store this information in `.sprsCache/pointfreeco/swift-clocks/<version>/manifests.json`:

```
{
  "manifests": [
    {
      "fileName": "Package.swift",
      "swiftToolsVersion": "5.9"
    },
    {
      "fileName": "Package@swift-6.0.swift",
      "swiftVersion": "6.0",
      "swiftToolsVersion": "6.0"
    }
  ]
}
```

Instead of a JSON file, we could move this information into a DB table called "manifests":

| Package Scope | Package Name   | Package Version | File Name                 | Swift Version | Swift Tools Version | Cache Path                                 |
| ------------- | -------------- | --------------- | ------------------------- | ------------- | ------------------- | ------------------------------------------ |
| `pointfreeco` | `swift-clocks` | `1.0.6`         | `Package.swift`           |               | `5.9`               | `<cache-path>/.../Package.swift`           |
| `pointfreeco` | `swift-clocks` | `1.0.6`         | `Package@swift-6.0.swift` | `6.0`         | `6.0`               | `<cache-path>/.../Package@swift-6.0.swift` |


## Move `releaseMetadata.json` into a DB table

Currently, we store Release Metadata information in a directory-specific
`releaseMetadata.json` file. For example, [swift-overture 0.5.0](https://github.com/pointfreeco/swift-overture/tree/0.5.0)
release metadata is stored in `.sprsCache/pointfreeco/swift-overture/0.5.0/releaseMetadata.json`:

```
{
  "checksum" : "13aedbe3a79154ef848290444ac754c5cf9fee9283f46a3a43645004a912063f",
  "publishedAt" : "2019-03-26T18:04:46Z",
  "tag" : {
    "apiLexicalOrder" : 0,
    "name" : "0.5.0",
    "nodeId" : "MDM6UmVmMTI4NzkxMTcwOnJlZnMvdGFncy8wLjUuMA==",
    "sha" : "7977acd7597f413717058acc1e080731249a1d7e",
    "zipBallURL" : "https://api.github.com/repos/pointfreeco/swift-overture/zipball/refs/tags/0.5.0"
  },
  "version" : "0.5.0"
}
```

Instead of a JSON file, we could move this information into a DB table called "releases":

| Package Scope | Package Name     | Package Version | Tag             | PublishedAt            | ZipBallURL          | Source Archive Path                        |
| ------------- | ---------------- | --------------- | --------------- | ---------------------- | ------------------- | ------------------------------------------ |
| `pointfreeco` | `swift-overture` | `0.5.0`         | `0.5.0`         | "2019-03-26T18:04:46Z" | "https://api.github.com/repos/pointfreeco/swift-overture/zipball/refs/tags/0.5.0" | `<cache-path>/.../foo.zip` |

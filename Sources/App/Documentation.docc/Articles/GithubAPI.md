#  Github API

We can implement a Swift Package Registry Service by using these four operations in the Github API:

1. [List Repository Tags](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-tags)
2. [Get A Release By Tag Name](https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#get-a-release-by-tag-name)
3. [Get Repository Content](https://docs.github.com/en/rest/repos/contents?apiVersion=2022-11-28#get-repository-content)
4. [Get Repository](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#get-a-repository)

## List Repository Tags

The [List Repository Tags](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-tags) endpoint
in the Github API provides a paginated list of tags for a repository:

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

### Tags vs Semantic Versions

Notice that the tags listed above are simply git tags. They can be whatever the repository
author wants them to be: "1.2.3", "v1.2.3", "version_1.2.3", or whatever.

The [Swift Package Registry Service Specification](https://github.com/swiftlang/swift-package-manager/blob/main/Documentation/PackageRegistry/Registry.md#2-definitions),
on the other hand, specifies that its versions MUST be semantic versions, as defined by
the [Semantic Versioning 2.0.0 spec](https://semver.org/). This spec has a regular
expression associate with it which explicitly defines how a Semantic Version must
be parsed. That means that:

* Tags like "1.2.3" ARE valid semantic versions; but
* Tags like "v1.2.3" or "version_1.2.3" are NOT.

This means that when we talk to the Github API, we must supply **tags**, but when we
receive requests and supply responses to the Swift Package Registry Service, then
we must provide **semantic versions**.

For most repositories, this is not a problem - their tags ARE semantic versions. However,
for a few repositories which use tags like "v1.2.3", we must provide the mapping between
semantic version and tag.

Swift Package Manager has to do this same thing. Therefore, we have tried to make our
logic for the tag <-> semantic version processing exactly the same as SPM. You can find
our processing of tags to semantic versions in [this file](https://github.com/CrowdStrike/swift-package-registry-service/blob/main/Sources/APIUtilities/Version%2BTagMap.swift).

## Get A Release By Tag Name

As mentioned in the discussion of the List Repository Tags Github endpoint above,
the tag information contains the tag **name** and **zipball_url**. However,
when we respond to the Swift Package Registry Service Fetch Release Metadata endpoint
(`GET /{owner}/{repo}/{version}`), then there is an optional `publishedAt` date
which indicates when that release was published. That information is not available
in the List Repository Tags Github endpoint, since there may or may not be
a Github "release" associated with a particular tag.

However, if there IS a release associated with a tag, we can look up information about that release using the
[Get A Release By Tag Name](https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#get-a-release-by-tag-name)
endpoint. That information includes when the release was published.

Here is an example of this endpoint:

```
$ curl -H "X-GitHub-Api-Version: 2022-11-28" \
       -H "Accept: application/vnd.github+json" \
       -H "Authorization: Bearer <your-PAT>" \
       --no-progress-meter \
       https://api.github.com/repos/pointfreeco/swift-overture/releases/tags/0.5.0
{
  "url": "https://api.github.com/repos/pointfreeco/swift-overture/releases/16362611",
  "assets_url": "https://api.github.com/repos/pointfreeco/swift-overture/releases/16362611/assets",
  "upload_url": "https://uploads.github.com/repos/pointfreeco/swift-overture/releases/16362611/assets{?name,label}",
  "html_url": "https://github.com/pointfreeco/swift-overture/releases/tag/0.5.0",
  "id": 16362611,
  "author": {
    "login": "stephencelis",
    "id": 658,
    "node_id": "MDQ6VXNlcjY1OA==",
    "avatar_url": "https://avatars.githubusercontent.com/u/658?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/stephencelis",
    "html_url": "https://github.com/stephencelis",
    "followers_url": "https://api.github.com/users/stephencelis/followers",
    "following_url": "https://api.github.com/users/stephencelis/following{/other_user}",
    "gists_url": "https://api.github.com/users/stephencelis/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/stephencelis/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/stephencelis/subscriptions",
    "organizations_url": "https://api.github.com/users/stephencelis/orgs",
    "repos_url": "https://api.github.com/users/stephencelis/repos",
    "events_url": "https://api.github.com/users/stephencelis/events{/privacy}",
    "received_events_url": "https://api.github.com/users/stephencelis/received_events",
    "type": "User",
    "user_view_type": "public",
    "site_admin": false
  },
  "node_id": "MDc6UmVsZWFzZTE2MzYyNjEx",
  "tag_name": "0.5.0",
  "target_commitish": "master",
  "name": "The Boring Swift 5 Release",
  "draft": false,
  "prerelease": false,
  "created_at": "2019-03-26T15:19:07Z",
  "published_at": "2019-03-26T18:04:46Z",
  "assets": [

  ],
  "tarball_url": "https://api.github.com/repos/pointfreeco/swift-overture/tarball/0.5.0",
  "zipball_url": "https://api.github.com/repos/pointfreeco/swift-overture/zipball/0.5.0",
  "body": "### What's new?\r\n\r\n- Not much! We build for Swift 5 now!"
}
```

Notice the `published_at` field.

So therefore, when we are responding to the Fetch Release Metadata endpoint,
we will call this Github API endpoint to fetch the `published_at` field.
However, given that there may not be a release associate with a specified tag,
then this is not an error if this endpoint returns a `404 Not Found`. In this
case, we simply don't provide the optional `publishedAt` field in the
`GET /{owner}/{repo}/{version}` response.

## Get Repository Content

In order to respond to the Swift Package Registry Service Fetch Manifest request
(`GET /{owner}/{repo}/{version}/Package.swift`), then we have to:

* **Find the information about all the package manifests are present in the repository**.
  Normally there is always a `Package.swift`, but there also could be Swift-version-specific
  manifests, like `Package@swift-6.0.swift`.
* **Fetch the actual content of any of the package manifests**.

We can do both of these things with the
[Get Repository Content](https://docs.github.com/en/rest/repos/contents?apiVersion=2022-11-28#get-repository-content)
endpoint:

* If the path we supply in the request is a directory, then the response is a listing of all the 
  files in that directory.
* If the path we supply in the request is a file, then the response is information about that
  file, including the Base64-encoded contents.

Here is an example of a directory request. Notice that the path after `contents/` and before
the query parameter `?ref=0.5.0` is empty, meaning the root directory of the repository:

```
curl -H "X-GitHub-Api-Version: 2022-11-28" \
     -H "Accept: application/vnd.github.object+json" \
     -H "Authorization: Bearer <your-PAT>" \
     --no-progress-meter \
     https://api.github.com/repos/pointfreeco/swift-overture/contents/?ref=0.5.0
{
  "name": "",
  "path": "",
  "sha": "940f5b5642eab4df8dfce2c34450565cf3329350",
  "size": 0,
  "url": "https://api.github.com/repos/pointfreeco/swift-overture/contents/?ref=0.5.0",
  "html_url": "https://github.com/pointfreeco/swift-overture/tree/0.5.0/",
  "git_url": "https://api.github.com/repos/pointfreeco/swift-overture/git/trees/940f5b5642eab4df8dfce2c34450565cf3329350",
  "download_url": null,
  "type": "dir",
  "_links": {
    "self": "https://api.github.com/repos/pointfreeco/swift-overture/contents/?ref=0.5.0",
    "git": "https://api.github.com/repos/pointfreeco/swift-overture/git/trees/940f5b5642eab4df8dfce2c34450565cf3329350",
    "html": "https://github.com/pointfreeco/swift-overture/tree/0.5.0/"
  },
  "entries": [
    {
      "name": ".circleci",
      "path": ".circleci",
      "sha": "d5e366c2e485bb0fba07997788a7902fad047e58",
      "size": 0,
      "url": "https://api.github.com/repos/pointfreeco/swift-overture/contents/.circleci?ref=0.5.0",
      "html_url": "https://github.com/pointfreeco/swift-overture/tree/0.5.0/.circleci",
      "git_url": "https://api.github.com/repos/pointfreeco/swift-overture/git/trees/d5e366c2e485bb0fba07997788a7902fad047e58",
      "download_url": null,
      "type": "dir",
      "_links": {
        "self": "https://api.github.com/repos/pointfreeco/swift-overture/contents/.circleci?ref=0.5.0",
        "git": "https://api.github.com/repos/pointfreeco/swift-overture/git/trees/d5e366c2e485bb0fba07997788a7902fad047e58",
        "html": "https://github.com/pointfreeco/swift-overture/tree/0.5.0/.circleci"
      }
    },
    {
      "name": ".gitignore",
      "path": ".gitignore",
      "sha": "47f8ac6a750f8d3bd4bd7ae704c24ec91bbbd367",
      "size": 1459,
      "url": "https://api.github.com/repos/pointfreeco/swift-overture/contents/.gitignore?ref=0.5.0",
      "html_url": "https://github.com/pointfreeco/swift-overture/blob/0.5.0/.gitignore",
      "git_url": "https://api.github.com/repos/pointfreeco/swift-overture/git/blobs/47f8ac6a750f8d3bd4bd7ae704c24ec91bbbd367",
      "download_url": "https://raw.githubusercontent.com/pointfreeco/swift-overture/0.5.0/.gitignore",
      "type": "file",
      "_links": {
        "self": "https://api.github.com/repos/pointfreeco/swift-overture/contents/.gitignore?ref=0.5.0",
        "git": "https://api.github.com/repos/pointfreeco/swift-overture/git/blobs/47f8ac6a750f8d3bd4bd7ae704c24ec91bbbd367",
        "html": "https://github.com/pointfreeco/swift-overture/blob/0.5.0/.gitignore"
      }
    },
    ...,
    {
      "name": "README.md",
      "path": "README.md",
      "sha": "807cf872e654bb73ecf66b1f6f5b5967d3f487ef",
      "size": 14313,
      "url": "https://api.github.com/repos/pointfreeco/swift-overture/contents/README.md?ref=0.5.0",
      "html_url": "https://github.com/pointfreeco/swift-overture/blob/0.5.0/README.md",
      "git_url": "https://api.github.com/repos/pointfreeco/swift-overture/git/blobs/807cf872e654bb73ecf66b1f6f5b5967d3f487ef",
      "download_url": "https://raw.githubusercontent.com/pointfreeco/swift-overture/0.5.0/README.md",
      "type": "file",
      "_links": {
        "self": "https://api.github.com/repos/pointfreeco/swift-overture/contents/README.md?ref=0.5.0",
        "git": "https://api.github.com/repos/pointfreeco/swift-overture/git/blobs/807cf872e654bb73ecf66b1f6f5b5967d3f487ef",
        "html": "https://github.com/pointfreeco/swift-overture/blob/0.5.0/README.md"
      }
    },
    {
      "name": "Sources",
      "path": "Sources",
      "sha": "0ee5006775c1962bb88badf5b0264e14a76c3a90",
      "size": 0,
      "url": "https://api.github.com/repos/pointfreeco/swift-overture/contents/Sources?ref=0.5.0",
      "html_url": "https://github.com/pointfreeco/swift-overture/tree/0.5.0/Sources",
      "git_url": "https://api.github.com/repos/pointfreeco/swift-overture/git/trees/0ee5006775c1962bb88badf5b0264e14a76c3a90",
      "download_url": null,
      "type": "dir",
      "_links": {
        "self": "https://api.github.com/repos/pointfreeco/swift-overture/contents/Sources?ref=0.5.0",
        "git": "https://api.github.com/repos/pointfreeco/swift-overture/git/trees/0ee5006775c1962bb88badf5b0264e14a76c3a90",
        "html": "https://github.com/pointfreeco/swift-overture/tree/0.5.0/Sources"
      }
    },
    {
      "name": "Tests",
      "path": "Tests",
      "sha": "1dabee2f47670f84e651bc8354ccbda2f1146f68",
      "size": 0,
      "url": "https://api.github.com/repos/pointfreeco/swift-overture/contents/Tests?ref=0.5.0",
      "html_url": "https://github.com/pointfreeco/swift-overture/tree/0.5.0/Tests",
      "git_url": "https://api.github.com/repos/pointfreeco/swift-overture/git/trees/1dabee2f47670f84e651bc8354ccbda2f1146f68",
      "download_url": null,
      "type": "dir",
      "_links": {
        "self": "https://api.github.com/repos/pointfreeco/swift-overture/contents/Tests?ref=0.5.0",
        "git": "https://api.github.com/repos/pointfreeco/swift-overture/git/trees/1dabee2f47670f84e651bc8354ccbda2f1146f68",
        "html": "https://github.com/pointfreeco/swift-overture/tree/0.5.0/Tests"
      }
    },
    {
      "name": "project.yml",
      "path": "project.yml",
      "sha": "2df81be56b63bf91973fc8b08f9409eaf209b43f",
      "size": 659,
      "url": "https://api.github.com/repos/pointfreeco/swift-overture/contents/project.yml?ref=0.5.0",
      "html_url": "https://github.com/pointfreeco/swift-overture/blob/0.5.0/project.yml",
      "git_url": "https://api.github.com/repos/pointfreeco/swift-overture/git/blobs/2df81be56b63bf91973fc8b08f9409eaf209b43f",
      "download_url": "https://raw.githubusercontent.com/pointfreeco/swift-overture/0.5.0/project.yml",
      "type": "file",
      "_links": {
        "self": "https://api.github.com/repos/pointfreeco/swift-overture/contents/project.yml?ref=0.5.0",
        "git": "https://api.github.com/repos/pointfreeco/swift-overture/git/blobs/2df81be56b63bf91973fc8b08f9409eaf209b43f",
        "html": "https://github.com/pointfreeco/swift-overture/blob/0.5.0/project.yml"
      }
    }
  ]
}
```

Here is an example of a file request for `Package.swift`:

```
curl -H "X-GitHub-Api-Version: 2022-11-28" \
     -H "Accept: application/vnd.github.object+json" \
     -H "Authorization: Bearer <your-PAT>" \
     --no-progress-meter \
     https://api.github.com/repos/pointfreeco/swift-overture/contents/Package.swift?ref=0.5.0
{
  "name": "Package.swift",
  "path": "Package.swift",
  "sha": "7bbcf4376a75c0a8ef77794497aabe1c624feaa3",
  "size": 576,
  "url": "https://api.github.com/repos/pointfreeco/swift-overture/contents/Package.swift?ref=0.5.0",
  "html_url": "https://github.com/pointfreeco/swift-overture/blob/0.5.0/Package.swift",
  "git_url": "https://api.github.com/repos/pointfreeco/swift-overture/git/blobs/7bbcf4376a75c0a8ef77794497aabe1c624feaa3",
  "download_url": "https://raw.githubusercontent.com/pointfreeco/swift-overture/0.5.0/Package.swift",
  "type": "file",
  "content": "Ly8gc3dpZnQtdG9vbHMtdmVyc2lvbjo1LjAKaW1wb3J0IEZvdW5kYXRpb24K\naW1wb3J0IFBhY2thZ2VEZXNjcmlwdGlvbgoKbGV0IHBhY2thZ2UgPSBQYWNr\nYWdlKAogIG5hbWU6ICJPdmVydHVyZSIsCiAgcHJvZHVjdHM6IFsKICAgIC5s\naWJyYXJ5KAogICAgICBuYW1lOiAiT3ZlcnR1cmUiLAogICAgICB0YXJnZXRz\nOiBbIk92ZXJ0dXJlIl0pLAogIF0sCiAgdGFyZ2V0czogWwogICAgLnRhcmdl\ndCgKICAgICAgbmFtZTogIk92ZXJ0dXJlIiwKICAgICAgZGVwZW5kZW5jaWVz\nOiBbXSksCiAgICAudGVzdFRhcmdldCgKICAgICAgbmFtZTogIk92ZXJ0dXJl\nVGVzdHMiLAogICAgICBkZXBlbmRlbmNpZXM6IFsiT3ZlcnR1cmUiXSksCiAg\nXQopCgppZiBQcm9jZXNzSW5mby5wcm9jZXNzSW5mby5lbnZpcm9ubWVudC5r\nZXlzLmNvbnRhaW5zKCJQRl9ERVZFTE9QIikgewogIHBhY2thZ2UuZGVwZW5k\nZW5jaWVzLmFwcGVuZCgKICAgIGNvbnRlbnRzT2Y6IFsKICAgICAgLnBhY2th\nZ2UodXJsOiAiaHR0cHM6Ly9naXRodWIuY29tL3lvbmFza29sYi9YY29kZUdl\nbi5naXQiLCBmcm9tOiAiMi4zLjAiKSwKICAgIF0KICApCn0K\n",
  "encoding": "base64",
  "_links": {
    "self": "https://api.github.com/repos/pointfreeco/swift-overture/contents/Package.swift?ref=0.5.0",
    "git": "https://api.github.com/repos/pointfreeco/swift-overture/git/blobs/7bbcf4376a75c0a8ef77794497aabe1c624feaa3",
    "html": "https://github.com/pointfreeco/swift-overture/blob/0.5.0/Package.swift"
  }
}
```

## Get Repository

In the Swift Package Registry Service
[Lookup Package Identifiers](https://github.com/swiftlang/swift-package-manager/blob/main/Documentation/PackageRegistry/Registry.md#45-lookup-package-identifiers-registered-for-a-url)
endpoint, the caller supplies an URL and the service returns one or more package
identifiers which are associated with that URL. We support three different types of URLs:

* "Clone" URLs in the form `https://github.com/{owner}/{repo}.git`
* "HTML" URLs in the form `https://github.com/{owner}/{repo}` (same as a Clone URL, but without
  the `.git` suffix.
* "SSH" URLs in the form `git@github.com:{owner}/{repo}.git`

So when we receive an URL in one of those forms, then we need to determine
whether there is a Github repository matching one of those URL forms.
We do this by parsing out the `{owner}` and `{repo}` from the URL
and then calling the
[Get Repository](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#get-a-repository)
Github API endpoint.

Here is an example of the Get Repository call:

```
curl -H "X-GitHub-Api-Version: 2022-11-28" \
     -H "Accept: application/vnd.github+json" \
     -H "Authorization: Bearer <your-PAT>" \
     --no-progress-meter \
     https://api.github.com/repos/pointfreeco/swift-overture
{
  "id": 128791170,
  "node_id": "MDEwOlJlcG9zaXRvcnkxMjg3OTExNzA=",
  "name": "swift-overture",
  "full_name": "pointfreeco/swift-overture",
  "private": false,
  "owner": {
    "login": "pointfreeco",
    "id": 29466629,
    "node_id": "MDEyOk9yZ2FuaXphdGlvbjI5NDY2NjI5",
    "avatar_url": "https://avatars.githubusercontent.com/u/29466629?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/pointfreeco",
    "html_url": "https://github.com/pointfreeco",
    "followers_url": "https://api.github.com/users/pointfreeco/followers",
    "following_url": "https://api.github.com/users/pointfreeco/following{/other_user}",
    "gists_url": "https://api.github.com/users/pointfreeco/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/pointfreeco/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/pointfreeco/subscriptions",
    "organizations_url": "https://api.github.com/users/pointfreeco/orgs",
    "repos_url": "https://api.github.com/users/pointfreeco/repos",
    "events_url": "https://api.github.com/users/pointfreeco/events{/privacy}",
    "received_events_url": "https://api.github.com/users/pointfreeco/received_events",
    "type": "Organization",
    "user_view_type": "public",
    "site_admin": false
  },
  "html_url": "https://github.com/pointfreeco/swift-overture",
  "description": "🎼 A library for function composition.",
  "fork": false,
  "url": "https://api.github.com/repos/pointfreeco/swift-overture",
  "forks_url": "https://api.github.com/repos/pointfreeco/swift-overture/forks",
  "keys_url": "https://api.github.com/repos/pointfreeco/swift-overture/keys{/key_id}",
  "collaborators_url": "https://api.github.com/repos/pointfreeco/swift-overture/collaborators{/collaborator}",
  "teams_url": "https://api.github.com/repos/pointfreeco/swift-overture/teams",
  "hooks_url": "https://api.github.com/repos/pointfreeco/swift-overture/hooks",
  "issue_events_url": "https://api.github.com/repos/pointfreeco/swift-overture/issues/events{/number}",
  "events_url": "https://api.github.com/repos/pointfreeco/swift-overture/events",
  "assignees_url": "https://api.github.com/repos/pointfreeco/swift-overture/assignees{/user}",
  "branches_url": "https://api.github.com/repos/pointfreeco/swift-overture/branches{/branch}",
  "tags_url": "https://api.github.com/repos/pointfreeco/swift-overture/tags",
  "blobs_url": "https://api.github.com/repos/pointfreeco/swift-overture/git/blobs{/sha}",
  "git_tags_url": "https://api.github.com/repos/pointfreeco/swift-overture/git/tags{/sha}",
  "git_refs_url": "https://api.github.com/repos/pointfreeco/swift-overture/git/refs{/sha}",
  "trees_url": "https://api.github.com/repos/pointfreeco/swift-overture/git/trees{/sha}",
  "statuses_url": "https://api.github.com/repos/pointfreeco/swift-overture/statuses/{sha}",
  "languages_url": "https://api.github.com/repos/pointfreeco/swift-overture/languages",
  "stargazers_url": "https://api.github.com/repos/pointfreeco/swift-overture/stargazers",
  "contributors_url": "https://api.github.com/repos/pointfreeco/swift-overture/contributors",
  "subscribers_url": "https://api.github.com/repos/pointfreeco/swift-overture/subscribers",
  "subscription_url": "https://api.github.com/repos/pointfreeco/swift-overture/subscription",
  "commits_url": "https://api.github.com/repos/pointfreeco/swift-overture/commits{/sha}",
  "git_commits_url": "https://api.github.com/repos/pointfreeco/swift-overture/git/commits{/sha}",
  "comments_url": "https://api.github.com/repos/pointfreeco/swift-overture/comments{/number}",
  "issue_comment_url": "https://api.github.com/repos/pointfreeco/swift-overture/issues/comments{/number}",
  "contents_url": "https://api.github.com/repos/pointfreeco/swift-overture/contents/{+path}",
  "compare_url": "https://api.github.com/repos/pointfreeco/swift-overture/compare/{base}...{head}",
  "merges_url": "https://api.github.com/repos/pointfreeco/swift-overture/merges",
  "archive_url": "https://api.github.com/repos/pointfreeco/swift-overture/{archive_format}{/ref}",
  "downloads_url": "https://api.github.com/repos/pointfreeco/swift-overture/downloads",
  "issues_url": "https://api.github.com/repos/pointfreeco/swift-overture/issues{/number}",
  "pulls_url": "https://api.github.com/repos/pointfreeco/swift-overture/pulls{/number}",
  "milestones_url": "https://api.github.com/repos/pointfreeco/swift-overture/milestones{/number}",
  "notifications_url": "https://api.github.com/repos/pointfreeco/swift-overture/notifications{?since,all,participating}",
  "labels_url": "https://api.github.com/repos/pointfreeco/swift-overture/labels{/name}",
  "releases_url": "https://api.github.com/repos/pointfreeco/swift-overture/releases{/id}",
  "deployments_url": "https://api.github.com/repos/pointfreeco/swift-overture/deployments",
  "created_at": "2018-04-09T15:12:57Z",
  "updated_at": "2025-03-09T05:11:55Z",
  "pushed_at": "2024-07-05T17:46:54Z",
  "git_url": "git://github.com/pointfreeco/swift-overture.git",
  "ssh_url": "git@github.com:pointfreeco/swift-overture.git",
  "clone_url": "https://github.com/pointfreeco/swift-overture.git",
  "svn_url": "https://github.com/pointfreeco/swift-overture",
  "homepage": "https://www.pointfree.co/episodes/ep11-composition-without-operators",
  "size": 168,
  "stargazers_count": 1143,
  "watchers_count": 1143,
  "language": "Swift",
  "has_issues": true,
  "has_projects": false,
  "has_downloads": true,
  "has_wiki": false,
  "has_pages": false,
  "has_discussions": true,
  "forks_count": 59,
  "mirror_url": null,
  "archived": false,
  "disabled": false,
  "open_issues_count": 1,
  "license": {
    "key": "mit",
    "name": "MIT License",
    "spdx_id": "MIT",
    "url": "https://api.github.com/licenses/mit",
    "node_id": "MDc6TGljZW5zZTEz"
  },
  "allow_forking": true,
  "is_template": false,
  "web_commit_signoff_required": false,
  "topics": [
    "function-composition",
    "functional-programming"
  ],
  "visibility": "public",
  "forks": 59,
  "open_issues": 1,
  "watchers": 1143,
  "default_branch": "main",
  "permissions": {
    "admin": false,
    "maintain": false,
    "push": false,
    "triage": false,
    "pull": true
  },
  "custom_properties": {

  },
  "organization": {
    "login": "pointfreeco",
    "id": 29466629,
    "node_id": "MDEyOk9yZ2FuaXphdGlvbjI5NDY2NjI5",
    "avatar_url": "https://avatars.githubusercontent.com/u/29466629?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/pointfreeco",
    "html_url": "https://github.com/pointfreeco",
    "followers_url": "https://api.github.com/users/pointfreeco/followers",
    "following_url": "https://api.github.com/users/pointfreeco/following{/other_user}",
    "gists_url": "https://api.github.com/users/pointfreeco/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/pointfreeco/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/pointfreeco/subscriptions",
    "organizations_url": "https://api.github.com/users/pointfreeco/orgs",
    "repos_url": "https://api.github.com/users/pointfreeco/repos",
    "events_url": "https://api.github.com/users/pointfreeco/events{/privacy}",
    "received_events_url": "https://api.github.com/users/pointfreeco/received_events",
    "type": "Organization",
    "user_view_type": "public",
    "site_admin": false
  },
  "network_count": 59,
  "subscribers_count": 25
}
```

The fields of interest to us are:

* `id` - a unique `Int64` identifier for this repository
* `clone_url` - the Clone URL for this repository
* `html_url` - the HTML URL for this repository
* `ssh_url` - the SSH URL for this repository


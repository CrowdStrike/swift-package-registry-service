# Getting started

Learn how to build and run the Swift Package Registry Service.

## Github Personal Access Token

Many methods of the [Github API](https://docs.github.com/en/rest?apiVersion=2022-11-28) is accessible without authentication.
However, the [rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28)
are much lower. Therefore, it is advisable to provide the service with a
[Github Personal Access Token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
to authenticate with the Github API.

## Building and running migrations

Check out the repo and do an initial build using the `swift` command line:

```
git clone https://github.com/CrowdStrike/swift-package-registry-service.git
cd swift-package-registry-service
swift build
```

Now let's set up the database which is used for parts of the disk cache:

```
swift run App migrate
```

You should see something like:

```
$ swift run App migrate
...
Build of product 'App' complete! (92.19s)
Migrate Command: Prepare
The following migration(s) will be prepared:
+ App.CreateRepositories on <default>
Would you like to continue?
y/n> 
```

Type 'y' and then hit Return. Then you should see:

```
y/n> y 
[ INFO ] [Migrator] Starting prepare [database-id: sqlite, migration: App.CreateRepositories]
[ INFO ] [Migrator] Finished prepare [database-id: sqlite, migration: App.CreateRepositories]
Migration successful
```

Now you should see a directory created called `.sprsCache` and a `db.sqlite` file inside that directory:

```
$ ls -l .sprsCache
total 48
-rw-r--r--  1 ehyche  staff  24576 Mar 24 14:27 db.sqlite
```

## Running the service from the command line

Now that you have created the disk cache database, then you are now ready to run the service:

```
$ export GITHUB_API_TOKEN="<your-Github-PAT>"
$ swift run App serve
Building for debugging...
...
Build of product 'App' complete! (25.07s)
[ NOTICE ] Server started on http://127.0.0.1:8080
```

## Testing the service using curl

Before you point Swift Package Manager at this service, you might want to do some simple curl's to see it run.
All of the examples below use [this repository](https://github.com/pointfreeco/swift-overture) as an example.

The sections below give examples of each of the 5 endpoints of the service.

### List Package Releases using curl

```
$ curl --no-progress-meter -H "Accept: application/vnd.swift.registry.v1+json" http://127.0.0.1:8080/pointfreeco/swift-overture
{
  "releases" : {
    "0.1.0" : {
      "url" : "http://127.0.0.1:8080/pointfreeco/swift-overture/0.1.0"
    },
    "0.2.0" : {
      "url" : "http://127.0.0.1:8080/pointfreeco/swift-overture/0.2.0"
    },
    "0.3.0" : {
      "url" : "http://127.0.0.1:8080/pointfreeco/swift-overture/0.3.0"
    },
    "0.3.1" : {
      "url" : "http://127.0.0.1:8080/pointfreeco/swift-overture/0.3.1"
    },
    "0.4.0" : {
      "url" : "http://127.0.0.1:8080/pointfreeco/swift-overture/0.4.0"
    },
    "0.5.0" : {
      "url" : "http://127.0.0.1:8080/pointfreeco/swift-overture/0.5.0"
    }
  }
}
```

### Fetch release metadata using curl

```
$ curl --no-progress-meter -H "Accept: application/vnd.swift.registry.v1+json" http://127.0.0.1:8080/pointfreeco/swift-overture/0.5.0
{
  "id" : "pointfreeco.swift-overture",
  "metadata" : {
    "repositoryURLs" : [
      "https://github.com/pointfreeco/swift-overture",
      "https://github.com/pointfreeco/swift-overture.git",
      "git@github.com:pointfreeco/swift-overture.git"
    ]
  },
  "publishedAt" : "2019-03-26T18:04:46Z",
  "resources" : [
    {
      "checksum" : "13aedbe3a79154ef848290444ac754c5cf9fee9283f46a3a43645004a912063f",
      "name" : "source-archive",
      "type" : "application/zip"
    }
  ],
  "version" : "0.5.0"
}
```

### Fetch manifest using curl

```
$ curl --verbose -H "Accept: application/vnd.swift.registry.v1+swift" http://127.0.0.1:8080/pointfreeco/swift-overture/0.5.0/Package.swift
// swift-tools-version:5.0
import Foundation
import PackageDescription

let package = Package(
  name: "Overture",
  products: [
    .library(
      name: "Overture",
      targets: ["Overture"]),
  ],
  targets: [
    .target(
      name: "Overture",
      dependencies: []),
    .testTarget(
      name: "OvertureTests",
      dependencies: ["Overture"]),
  ]
)

if ProcessInfo.processInfo.environment.keys.contains("PF_DEVELOP") {
  package.dependencies.append(
    contentsOf: [
      .package(url: "https://github.com/yonaskolb/XcodeGen.git", from: "2.3.0"),
    ]
  )
}
```

### Download Source Archive via curl

```
$ curl --no-progress-meter -H "Accept: application/vnd.swift.registry.v1+zip" --output swift-overture-0.5.0.zip http://127.0.0.1:8080/pointfreeco/swift-overture/0.5.0.zip
```

After running you should see a file called `swift-overture-0.5.0.zip`.

### Lookup Package Identifiers via curl

```
$ curl --no-progress-meter -H "Accept: application/vnd.swift.registry.v1+json" "http://127.0.0.1:8080/identifiers?url=https://github.com/pointfreeco/swift-overture.git"
{
  "identifiers" : [
    "pointfreeco.swift-overture"
  ]
}
```

## Building and Running Using Xcode

If you want to run and debug the service using Xcode, first do the "Building and running migrations" step above, then do the following:

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

## Changing the logging level

The Vapor log levels are:

* **Trace**: Messages that contain information normally of use only when tracing the execution of a program.
* **Debug**: Messages that contain information normally of use only when debugging a program.
* **Info**: Informational messages.
* **Notice**: Conditions that are not error conditions, but that may require special handling.
* **Warning**: Messages that are not error conditions, but more severe than Notice.
* **Error**: Error conditions.
* **Critical**: Critical error conditions that usually require immediate attention.

The default Vapor logging level is Info. If you want to change the logging level, see the
instructions below.

### Using Xcode

1. Click the `swift-package-registry-service` scheme.
2. Click Edit Scheme.
3. Click the Run action in the left pane.
4. Click the Arguments tab in the top middle.
5. Add a `--log <log-level>` argument, where `<log-level>` is `trace`, `debug`, `info`, `notice`,
   `warning`, `error`, or `critical`.

### Using swift command line

Add a `--log <log-level>` to your `swift run` command, where `<log-level>` is `trace`,
`debug`, `info`, `notice`, `warning`, `error`, or `critical`. For example, to set `debug`-level logging:

```
swift run --log debug
```

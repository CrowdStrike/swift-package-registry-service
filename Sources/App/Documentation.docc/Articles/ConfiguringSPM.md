# Configuring Swift Package Manager

Learn how to configure your Swift Package Manager to use the package registry.

## Configuring Swift Package Manager using the command line

You will need to configure Swift Package Manager to be aware of the package registry server.
If you are running `swift-package-registy-server` as localhost, then you can
tell Swift Package Manager this as follows:

```
$ swift package-registry set --global --allow-insecure-http http://127.0.0.1:8080
```

This will place this information in `~/.swiftpm/configuration/registries.json` and will
be global for all packages and projects on this machine.

On the other hand, if you only want to configure a single package or project, then leave
out the `--global` flag above:

```
$ cd ~/src/some-project-to-configure
$ swift package-registry set --allow-insecure-http http://127.0.0.1:8080
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
$ cd ~/src/my-package
$ swift build --replace-scm-with-registry
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

## Specifying transitive dependency in Xcode

You can tell Xcode how to resolve transitive dependencies by setting an Xcode default:

```
$ defaults write com.apple.dt.Xcode IDEPackageDependencySCMToRegistryTransformation <xcodebuild-option>
```

where `xcodebuild-option` are the same as the options above for `xcodebuild`:

1. Option 1: `none`
2. Option 2: `useRegistryIdentity`
3. Option 3: `useRegistryIdentityAndSources`

For example, if you wanted the equivalent of the command-line `--replace-scm-with-registry` option, you would do:

```
$ defaults write com.apple.dt.Xcode IDEPackageDependencySCMToRegistryTransformation useRegistryIdentityAndSources
```

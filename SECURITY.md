![CrowdStrike Swift Package Registry Service](https://github.com/CrowdStrike/swift-package-registry-service/blob/main/docs/assets/cs-logo.png?raw=true#gh-light-mode-only)
![CrowdStrike Swift Package Registry Service](https://github.com/CrowdStrike/swift-package-registry-service/blob/main/docs/assets/cs-logo-red.png?raw=true#gh-dark-mode-only)


# Security Policy
This document outlines security policy and procedures for the CrowdStrike `swift-package-registry-service` project.

+ [Supported Swift versions](#supported-swift-versions)
+ [Supported Swift Package Manager versions](#supported-swift-package-manager-versions)
+ [Supported Operating Systems](#supported-operating-systems)
+ [Reporting a potential security vulnerability](#reporting-a-potential-security-vulnerability)
+ [Disclosure and Mitigation Process](#disclosure-and-mitigation-process)

## Supported Swift versions

`swift-package-registry-service` is supported on all versions of Swift
where [Vapor is supported](https://docs.vapor.codes/install/linux/#install-on-linux).

| Version | Supported |
| :------- | :--------: |
| 6.0  | ![Yes](https://img.shields.io/badge/-YES-green) |
| 5.9  | ![Yes](https://img.shields.io/badge/-YES-green) |

## Supported Swift Package Manager versions

Most features and most respositories will work with all versions of
[Swift Package Manager](https://github.com/swiftlang/swift-package-manager)
which support package registries, which is >= 5.8.

However, there are a few cases which will only work with more recent versions of Swift Package Manager:

* Support for pagination on the List Package Releases endpoint (`GET /{owner}/{repo}`)
  needs [this change](https://github.com/swiftlang/swift-package-manager/pull/8219).
  This change will likely be released in Swift 6.1.
* For some packages where where the capitalization of the package references do not match the package identifier,
  [this change](https://github.com/swiftlang/swift-package-manager/pull/8194)
  is needed. This change will likely be released in Swift 6.1.

## Supported Operating Systems

Currently, `swift-package-registry-service` is only supported on macOS. However, we intend to eventually
support all OS's where [Vapor is supported](https://docs.vapor.codes/install/linux/#supported-distributions-and-versions).

## Reporting a potential security vulnerability

We have multiple avenues to receive security-related vulnerability reports.

Please report suspected security vulnerabilities by:
+ Submitting a [bug](https://github.com/CrowdStrike/swift-package-registry-service/issues/new).
+ Submitting a [pull request](https://github.com/CrowdStrike/swift-package-registry-service/pulls) to potentially resolve the issue.
+ Sending an email to __oss-security@crowdstrike.com__.

## Comments

If you have suggestions on how this process could be improved, please let us know by [starting a new discussion](https://github.com/CrowdStrike/swift-package-registry-service/discussions).

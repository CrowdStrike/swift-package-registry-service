#!/bin/bash
#
# Calls the fetchManifest endpoint of a Swift Package Registry service running in localhost
# https://github.com/swiftlang/swift-package-manager/blob/main/Documentation/PackageRegistry/Registry.md#43-fetch-manifest-for-a-package-release
#

set -euo pipefail

if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    echo "Usage: $0 <scope> <name> <version> [<swift-version>]"
    echo
    echo "where:"
    echo "    <scope>: The repository scope organization. (required)"
    echo "    <name>:  The repository name. (required)"
    echo "    <version>: The repository release version. (required)"
    echo "    <swift-version>: The swift version of the package manifest. (optional)"
    echo
    echo "Examples:"
    echo "    $0 pointfreeco swift-composable-architecture 1.15.2"
    echo "    $0 pointfreeco swift-composable-architecture 1.18.0 6.0"
    exit 1
fi

URL="http://127.0.0.1:8080/$1/$2/$3/Package.swift"

if [ $# -eq 4 ]; then
    URL=$URL?swift-version=$4
fi

curl --no-progress-meter -H "Accept: application/vnd.swift.registry.v1+swift" $URL

#!/bin/bash
#
# Calls the fetchReleaseMetadata endpoint of a Swift Package Registry service running in localhost
# https://github.com/swiftlang/swift-package-manager/blob/main/Documentation/PackageRegistry/Registry.md#42-fetch-information-about-a-package-release
#

set -euo pipefail

if [ $# -lt 3 ] || [ $# -gt 3 ]; then
    echo "Usage: $0 <scope> <name> <version>"
    echo
    echo "where:"
    echo "    <scope>: The repository scope organization. (required)"
    echo "     <name>: The repository name. (required)"
    echo "  <version>: The semantic version of the repository (required)"
    echo
    echo "Examples:"
    echo "    $0 pointfreeco swift-overture 0.5.0"
    exit 1
fi

URL="http://127.0.0.1:8080/$1/$2/$3"

curl --no-progress-meter -H "Accept: application/vnd.swift.registry.v1+json" $URL

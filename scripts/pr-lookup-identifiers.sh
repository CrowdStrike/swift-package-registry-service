#!/bin/bash
#
# Calls the lookupIdentifiers endpoint of a Swift Package Registry service running in localhost
# https://github.com/swiftlang/swift-package-manager/blob/main/Documentation/PackageRegistry/Registry.md#45-lookup-package-identifiers-registered-for-a-url
#

set -euo pipefail

if [ $# -lt 2 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <scope> <name>"
    echo
    echo "where:"
    echo "   <scope>: The repository scope organization. (required)"
    echo "    <name>: The repository name. (required)"
    echo
    echo "Examples:"
    echo "    $0 pointfreeco swift-composable-architecture"
    echo "    $0 apple swift-async-algorithms"
    exit 1
fi

GITHUB_URL="https://github.com/$1/$2.git"
URL="http://127.0.0.1:8080/identifiers?url=$GITHUB_URL"

curl --no-progress-meter -H "Accept: application/vnd.swift.registry.v1+json" $URL

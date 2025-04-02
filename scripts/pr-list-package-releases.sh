#!/bin/bash
#
# Calls the listPackageReleases endpoint of a Swift Package Registry service running in localhost
# https://github.com/swiftlang/swift-package-manager/blob/main/Documentation/PackageRegistry/Registry.md#41-list-package-releases
#

set -euo pipefail

if [ $# -lt 2 ] || [ $# -eq 3 ] || [ $# -gt 4 ]; then
    echo "Usage: $0 <scope> <name> [<per-page> <page>]"
    echo
    echo "where:"
    echo "    <scope>: The repository scope organization. (required)"
    echo "    <name>:  The repository name. (required)"
    echo "    <per-page>: Number of results per page. (optional)"
    echo "    <page>: The page number of results to fetch. (optional)"
    echo
    echo "Examples:"
    echo "    $0 pointfreeco swift-composable-architecture"
    echo "    $0 swiftlang swift-syntax 100 2"
    exit 1
fi

URL="http://127.0.0.1:8080/$1/$2"

if [ $# -eq 4 ]; then
    URL="$URL?per_page=$3&page=$4"
fi

curl --no-progress-meter -H "Accept: application/vnd.swift.registry.v1+json" $URL

#!/bin/bash
#
# Calls the downloadSourceArchive endpoint of a Swift Package Registry service running in localhost
# https://github.com/swiftlang/swift-package-manager/blob/main/Documentation/PackageRegistry/Registry.md#44-download-source-archive
#

set -euo pipefail

if [ $# -lt 4 ] || [ $# -gt 4 ]; then
    echo "Usage: $0 <scope> <name> <version> <zip>"
    echo
    echo "where:"
    echo "   <scope>: The repository scope organization. (required)"
    echo "    <name>: The repository name. (required)"
    echo " <version>: The repository release version. (required)"
    echo "     <zip>: The path to an output .zip file"
    echo
    echo "Examples:"
    echo "    $0 pointfreeco swift-overture 0.5.0 swift-overture-0.5.0.zip"
    exit 1
fi

URL="http://127.0.0.1:8080/$1/$2/$3.zip"

curl --no-progress-meter -H "Accept: application/vnd.swift.registry.v1+zip" --output $4 $URL

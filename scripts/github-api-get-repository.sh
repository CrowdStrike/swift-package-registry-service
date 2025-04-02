#!/bin/bash
#
# This calls the "Get Repository" Github API endpoint.
# https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#get-a-repository
#

set -euo pipefail

if [[ -z "${GITHUB_API_TOKEN+x}" ]]; then
    echo "The environment variable GITHUB_API_TOKEN is not set."
    echo "Please set GITHUB_API_TOKEN to the value of a Github Personal Access Token and retry."
    exit 1
fi

if [ $# -lt 2 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <owner> <repo>"
    echo
    echo "where:"
    echo "   <owner>: The repository scope organization. (required)"
    echo "    <repo>: The repository name. (required)"
    echo
    echo "Examples:"
    echo "    $0 pointfreeco swift-composable-architecture"
    echo "    $0 swiftlang swift-syntax"
    exit 1
fi

URL="https://api.github.com/repos/$1/$2"

curl -H "X-GitHub-Api-Version: 2022-11-28" \
     -H "Accept: application/vnd.github+json" \
     -H "Authorization: Bearer $GITHUB_API_TOKEN" \
     --no-progress-meter \
     $URL

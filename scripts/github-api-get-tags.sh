#!/bin/bash
#
# This calls the "List Tags" Github API endpoint.
#
# https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-tags

set -euo pipefail

if [[ -z "${GITHUB_API_TOKEN+x}" ]]; then
    echo "The environment variable GITHUB_API_TOKEN is not set."
    echo "Please set GITHUB_API_TOKEN to the value of a Github Personal Access Token and retry."
    exit 1
fi

if [ $# -lt 2 ] || [ $# -eq 3 ] || [ $# -gt 4 ]; then
    echo "Usage: $0 <owner> <repo> [<per-page> <page>]"
    echo
    echo "where:"
    echo "    <owner>: The repository scope organization. (required)"
    echo "    <repo>:  The repository name. (required)"
    echo "    <per-page>: Number of results per page. (optional)"
    echo "    <page>: The page number of results to fetch. (optional)"
    echo
    echo "Examples:"
    echo "    $0 pointfreeco swift-composable-architecture"
    echo "    $0 swiftlang swift-syntax 100 2"
    exit 1
fi

URL="https://api.github.com/repos/$1/$2/tags"

if [ $# -eq 4 ]; then
    URL="$URL?per_page=$3&page=$4"
fi

curl -H "X-GitHub-Api-Version: 2022-11-28" \
     -H "Accept: application/vnd.github+json" \
     -H "Authorization: Bearer $GITHUB_API_TOKEN" \
     --no-progress-meter \
     $URL

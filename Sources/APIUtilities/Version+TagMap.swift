/// It is very important that the package registry server parses tags to Semantic Versions
/// **exactly** how Swift Package Manager does. Swift Package Manager parses git tags into Semantic Versions
/// [here](https://github.com/swiftlang/swift-package-manager/blob/60b491399bf03306d738abcc71f77e67eb7c3b5e/Sources/Workspace/PackageContainer/SourceControlPackageContainer.swift#L107).
///
/// We re-create that logic in this extension.
///
extension Version {
    public static func versionToTagMap(fromTags tags: [String]) -> [Version: String] {
        // First produce a map from a semantic version to multiple tags
        let versionToTags = versionToTagsMap(from: tags)
        // Now if there are multiple tags which map to the same
        // semantic version, then select only one of them.
        return versionToTags.mapValues { tagsForSemanticVersion -> String in
            if tagsForSemanticVersion.count > 1 {
                // If multiple tags are present with the same semantic version (e.g. v1.0.0, 1.0.0, 1.0),
                // reconcile which one we prefer.
                //
                // Prefer the most specific tag, e.g. 1.0.0 is preferred over 1.0.
                // Sort the tags so the most specific tag is first, order is ascending so the most specific tag will be last
                let tagsSortedBySpecificity = tagsForSemanticVersion.sorted { lhs, rhs in
                    let componentCounts = (lhs.components(separatedBy: ".").count, rhs.components(separatedBy: ".").count)
                    if componentCounts.0 == componentCounts.1 {
                        // if they are both have the same number of components, favor the one without a v prefix.
                        // this matches previously defined behavior
                        // this assumes we can only enter this situation because one tag has a v prefix and the other does not.
                        return lhs.hasPrefix("v")
                    }
                    return componentCounts.0 < componentCounts.1
                }
                // Use the last one
                return tagsSortedBySpecificity[tagsSortedBySpecificity.count - 1]
            } else {
                // There is only one tag in the array, so use that one.
                return tagsForSemanticVersion[0]
            }
        }
    }

    private static func versionToTagsMap(from tags: [String]) -> [Version: [String]] {
        var map = [Version: [String]]()

        // Unlike the SPM implementation, we do not handle the
        // tags that are swift-tools-version-specific: that is,
        // they end in something like "@swift-6.0".
        for tag in tags {
            if let version = Version(tag: tag) {
                map[version, default: []].append(tag)
            }
        }

        return map
    }
}

#!/usr/bin/env bash
# Verifies a release tag against the repo. Usage: check_release.sh v3.0.0
# Fails unless: tag == pubspec version, and CHANGELOG.md has a matching entry.
set -euo pipefail

tag="${1:?usage: check_release.sh <tag, e.g. v3.0.0>}"
version="${tag#v}"

pubspec_version="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | tr -d '\r' | head -n1)"
if [[ "$pubspec_version" != "$version" ]]; then
  echo "::error::Tag $tag does not match pubspec.yaml version $pubspec_version"
  exit 1
fi

if ! grep -Eq "^## ${version//./\\.}( |\$)" CHANGELOG.md; then
  echo "::error::CHANGELOG.md has no '## $version' entry"
  exit 1
fi

echo "OK: $tag matches pubspec.yaml and CHANGELOG.md"

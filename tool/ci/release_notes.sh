#!/usr/bin/env bash
# Prints the CHANGELOG.md section for a version. Usage: release_notes.sh 3.0.0
set -euo pipefail
version="${1:?usage: release_notes.sh <version>}"
awk -v v="$version" '
  $0 ~ "^## " v "( |$)" { found=1; next }
  found && /^## / { exit }
  found && /^---$/ { next }
  found { print }
' CHANGELOG.md | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'

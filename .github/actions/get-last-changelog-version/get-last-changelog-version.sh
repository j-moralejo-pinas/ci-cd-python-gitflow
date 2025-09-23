#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# 1: Path to the changelog file (default: CHANGELOG.md)

CHANGELOG_PATH="${1:-CHANGELOG.md}"

if [[ -f "${CHANGELOG_PATH}" ]]; then
  LAST_TAG=$(awk '/^##[[:space:]]+v?[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+-[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}/{print $2; exit}' "${CHANGELOG_PATH}" || true)
  echo "last_tag=${LAST_TAG:-}" >> "${GITHUB_OUTPUT}"
else
  echo "last_tag=" >> "${GITHUB_OUTPUT}"
fi

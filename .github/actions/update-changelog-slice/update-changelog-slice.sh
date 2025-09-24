#!/usr/bin/env bash
set -euo pipefail

# Required env vars:
# - PAT_TOKEN: token for GitHub CLI auth
# - PRS: space-separated list of PR numbers
# - VERSION: tag for the new changelog entry (e.g., vX.Y.Z)
# - CHANGELOG_PATH: path to changelog (default CHANGELOG.rst)

PAT_TOKEN="${PAT_TOKEN:-}"
PRS="${PRS:-}"
VERSION="${VERSION:-}"
CHANGELOG_PATH="${CHANGELOG_PATH:-CHANGELOG.rst}"

if [[ -z "${PRS// /}" ]]; then
  echo "No PR numbers provided; creating changelog entry with version header only." >&2
  CHANGELOG_WORDS=""
else
  # 1) Get PR bodies and keep only '- <Word>:' lines
  CHANGELOG_WORDS="$({
    # Convert space-separated PR numbers to array and process each
    for n in ${PRS}; do
      [[ -z "$n" ]] && continue
      gh pr view "$n" --json body --jq '.body // ""'
    done \
    | awk '/^- [[:alpha:]]+: /'
  })"

  echo "Collected lines:"
  printf '%s\n' "$CHANGELOG_WORDS"
fi

# 2) Format grouped changelog in RST format
CHANGELOG_RST="$({
  awk '
    match($0,/^- ([A-Za-z]+):[[:space:]]*(.*)$/,m){
      w=m[1]; t=m[2]
      sub(/^[[:space:]]+|[[:space:]]+$/,"",t)
      if(!(w in seen)){ seen[w]=1; ord[++n]=w }
      if(length(t)) items[w]=items[w] "* " t ORS
    }
    END{
      for(i=1;i<=n;i++){
        w=ord[i]
        printf "%s\n", w
        printf "%s\n", gsub(/./, "-", w) ? gensub(/./, "-", "g", w) : ""
        printf "%s\n", items[w]
      }
    }
  ' <<< "$CHANGELOG_WORDS"
})"

printf '%s\n' "$CHANGELOG_RST"

# 3) Prepend entry to CHANGELOG
DATE="$(date -u +%Y-%m-%d)"
# Create RST-style header with underline
HEADER="${VERSION} - ${DATE}"
HEADER_UNDERLINE=$(printf '%*s' ${#HEADER} | tr ' ' '=')
VERSION_HEADER="${HEADER}"$'\n'"${HEADER_UNDERLINE}"

# Always write changelog entry, even if no content
if [[ -z "${CHANGELOG_RST// }" ]]; then
  echo "No changelog content found. Writing version header only."
  CHANGELOG_CONTENT="${VERSION_HEADER}"
else
  CHANGELOG_CONTENT="${VERSION_HEADER}"$'\n\n'"${CHANGELOG_RST}"
fi

# Define the standard changelog header
CHANGELOG_HEADER="=========
Changelog
=========

Sources to write the changelog:
- https://keepachangelog.com/en/1.0.0/
- https://semver.org/"

if [[ -f "${CHANGELOG_PATH}" ]]; then
  # Check if file starts with the standard header
  if head -n7 "${CHANGELOG_PATH}" | grep -q "=========.*Changelog.*=========" ; then
    # File has the header, preserve it and insert new entry after it
    { head -n7 "${CHANGELOG_PATH}"
      printf '\n\n'
      printf '%s\n\n' "$CHANGELOG_CONTENT"
      tail -n +8 "${CHANGELOG_PATH}"; } > "${CHANGELOG_PATH}.new"
  else
    # File exists but doesn't have the header, add header and content
    { printf '%s\n\n\n' "$CHANGELOG_HEADER"
      printf '%s\n\n' "$CHANGELOG_CONTENT"
      cat "${CHANGELOG_PATH}"; } > "${CHANGELOG_PATH}.new"
  fi
else
  # File doesn't exist, create with header and content
  { printf '%s\n\n\n' "$CHANGELOG_HEADER"
    printf '%s\n\n' "$CHANGELOG_CONTENT"; } > "${CHANGELOG_PATH}.new"
fi

mv "${CHANGELOG_PATH}.new" "${CHANGELOG_PATH}"

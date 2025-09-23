#!/usr/bin/env bash
set -euo pipefail

# Required env vars:
# - PAT_TOKEN: token for GitHub CLI auth
# - PRS: newline-separated list of PR numbers
# - VERSION: tag for the new changelog entry (e.g., vX.Y.Z)
# - CHANGELOG_PATH: path to changelog (default CHANGELOG.rst)

PAT_TOKEN="${PAT_TOKEN:-}"
PRS="${PRS:-}"
VERSION="${VERSION:-}"
CHANGELOG_PATH="${CHANGELOG_PATH:-CHANGELOG.rst}"

if [[ -z "${PRS//[$'\n' ]/}" ]]; then
  echo "No PR numbers provided; nothing to include in changelog." >&2
  exit 0
fi

# 1) Get PR bodies and keep only '# <Word>:' lines
CHANGELOG_WORDS="$({
  while IFS= read -r n; do
    [[ -z "$n" ]] && continue
    gh pr view "$n" --json body --jq '.body // ""'
  done <<< "$PRS" \
  | awk '/^# [[:alpha:]]+: /'
})"

echo "Collected lines:"
printf '%s\n' "$CHANGELOG_WORDS"

# 2) Format grouped changelog
CHANGELOG_MD="$({
  awk '
    match($0,/^# ([A-Za-z]+):[[:space:]]*(.*)$/,m){
      w=m[1]; t=m[2]
      sub(/^[[:space:]]+|[[:space:]]+$/,"",t)
      if(!(w in seen)){ seen[w]=1; ord[++n]=w }
      if(length(t)) items[w]=items[w] "- " t ORS
    }
    END{
      for(i=1;i<=n;i++){
        w=ord[i]
        printf "### %s\n%s\n", w, items[w]
      }
    }
  ' <<< "$CHANGELOG_WORDS"
})"

printf '%s\n' "$CHANGELOG_MD"

# 3) Prepend entry to CHANGELOG
if [[ -z "${CHANGELOG_MD// }" ]]; then
  echo "No changelog content to add. Skipping."
  exit 0
fi

DATE="$(date -u +%Y-%m-%d)"
HEADER="## ${VERSION} - ${DATE}"

if [[ -f "${CHANGELOG_PATH}" ]] && head -n1 "${CHANGELOG_PATH}" | grep -q '^# ' ; then
  { head -n1 "${CHANGELOG_PATH}"
    printf '\n'
    printf '%s\n\n%s\n\n' "$HEADER" "$CHANGELOG_MD"
    tail -n +2 "${CHANGELOG_PATH}"; } > "${CHANGELOG_PATH}.new"
else
  { printf '%s\n\n%s\n\n' "$HEADER" "$CHANGELOG_MD"
    [[ -f "${CHANGELOG_PATH}" ]] && cat "${CHANGELOG_PATH}"; } > "${CHANGELOG_PATH}.new"
fi

mv "${CHANGELOG_PATH}.new" "${CHANGELOG_PATH}"

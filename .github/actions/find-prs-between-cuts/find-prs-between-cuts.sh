#!/usr/bin/env bash
set -euo pipefail

REPO_SLUG="${REPO_SLUG:-}"
DEV_BRANCH="${DEV_BRANCH:-dev}"
PREV_CUT="${PREV_CUT:-}"
CUR_CUT="${CUR_CUT:-}"

git fetch origin --prune

PRS=$(git rev-list --reverse --first-parent "${PREV_CUT}..${CUR_CUT}" \
  | xargs -n1 -I{} gh api "repos/${REPO_SLUG}/commits/{}/pulls" \
       -H "Accept: application/vnd.github+json" \
       --jq "map(select(.base.ref==\"${DEV_BRANCH}\")) | .[].number" \
  | awk '!seen[$0]++')

{
  echo 'numbers<<__EOF__'
  printf '%s\n' "${PRS}"
  echo '__EOF__'
} >> "${GITHUB_OUTPUT}"

echo "PRs between cuts:"
printf '%s\n' "${PRS}"

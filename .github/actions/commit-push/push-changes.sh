#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# 1: Personal Access Token (PAT)
# 2: Repo (owner/repo)
# 3: Branch name

PAT="${1:-}"
REPO="${2:-}"
BRANCH="${3:-}"

if [[ -z "${PAT}" ]]; then
  echo "PAT not provided, skipping push." >&2
  exit 0
fi

# Clear any existing credential helpers to ensure we only use the PAT
git config --local --unset-all credential.helper || true
git config --local --unset-all credential.username || true

# Push directly to the PAT-authenticated URL without modifying the remote
git push "https://${PAT}@github.com/${REPO}.git" "HEAD:${BRANCH}"
echo "did_push=true" >> "${GITHUB_OUTPUT}"

#!/bin/sh
# Force-pushes the install tree as the single commit of an orphan branch.
#
# Each run replaces the branch outright, so old blobs become unreachable instead
# of accumulating in the repository forever.
set -e

BRANCH="$1"
ROOT="${2:-installed}"

if [ -z "$BRANCH" ]; then
  echo "usage: $0 <branch> [install-root]" >&2
  exit 1
fi
if [ -z "$GITHUB_TOKEN" ]; then
  echo "GITHUB_TOKEN is not set" >&2
  exit 1
fi

cd "$ROOT"

# Nothing in the payload is text that git should be reinterpreting - notably the
# gdb python helpers and linker scripts must reach Linux users with LF endings
# even though one of the three builds runs on Windows.
printf '* -text\n' >.gitattributes

rm -rf .git
git init -q
git config core.autocrlf false
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git checkout -q -b "$BRANCH"
git add -A
git commit -q -m "${COMMIT_MESSAGE:-Build ${BRANCH}}"

git push --force --quiet \
  "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" \
  "HEAD:${BRANCH}"

echo "Pushed $(git rev-parse --short HEAD) to ${BRANCH}"

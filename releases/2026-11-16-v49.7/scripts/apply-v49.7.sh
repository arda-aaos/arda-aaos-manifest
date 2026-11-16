#!/usr/bin/env bash
set -euo pipefail
# Replays V49.7 only on clean EXACT upstream bases, with a two-pass preflight.
# Intended for a future source checkout; NEVER called by the persist script.
ROOT="${1:?Usage: apply-v49.7.sh /path/to/aosp-root}"
BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
specs=(
  "external/libudev-zero|6f093b428ecae5138654b61d7f29871cef8739dc|libudev-zero.patch|c06b073f6eeb73b0fc3a6e5d04510133fefc0f31"
  "packages/apps/Car/Cluster|7244742c0268e1a1f6e88f5b2e1df0c0ec2c825a|cluster-v42.patch|d3ca1c09f243c4f5b25a3350dad0c0fae6f40843"
)
# Fail before the first write if EITHER tree is dirty, divergent or unpatchable.
for spec in "${specs[@]}"; do
  IFS='|' read -r rel base file expected_tree <<< "$spec"
  target="$ROOT/$rel"; patch="$BUNDLE_DIR/patches/$file"
  test -f "$patch" || { echo "PATCH_MISSING=$patch" >&2; exit 3; }
  test -d "$target" || { echo "PROJECT_MISSING=$target" >&2; exit 3; }
  current="$(git -C "$target" rev-parse HEAD)"
  tree="$(git -C "$target" rev-parse 'HEAD^{tree}')"
  [[ -z "$(git -C "$target" status --porcelain -uall)" ]] || { echo "NOT_CLEAN=$rel" >&2; exit 4; }
  if [[ "$tree" == "$expected_tree" ]]; then continue; fi
  [[ "$current" == "$base" ]] || { echo "BASE_SHA_MISMATCH=$rel $current" >&2; exit 4; }
  git -C "$target" apply --index --check "$patch"
done
for spec in "${specs[@]}"; do
  IFS='|' read -r rel base file expected_tree <<< "$spec"
  target="$ROOT/$rel"; patch="$BUNDLE_DIR/patches/$file"
  tree="$(git -C "$target" rev-parse 'HEAD^{tree}')"
  if [[ "$tree" == "$expected_tree" ]]; then
    echo "ALREADY_APPLIED=$rel";continue
  fi
  git -C "$target" apply --index "$patch"
  actual="$(git -C "$target" write-tree)"
  [[ "$actual" == "$expected_tree" ]] || { echo "TREE_MISMATCH=$rel $actual" >&2; exit 5; }
  git -C "$target" -c commit.gpgsign=false -c user.name='ARDA Release' \
    -c user.email='arda-release@users.noreply.github.com' \
    commit -m 'ARDA: apply V49.7 verified upstream source patch' >/dev/null
  [[ -z "$(git -C "$target" status --porcelain -uall)" ]] || exit 5
  echo "APPLIED_VERIFIED=$rel $actual"
done
printf '%s\n' 'V49_7_SOURCE_PATCHES=PASS'

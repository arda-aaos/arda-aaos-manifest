#!/usr/bin/env bash
# ARDA organization manifest publisher — guarded, non-interactive, fast-forward only.
# Prepared from verified a85ead3 GitHub main; explicit owner+base+HEAD confirmation required.
set -Eeuo pipefail
fail() { echo "ARDA_STOP=$1" >&2; exit 2; }
[[ "${ARDA_MANIFEST_PUBLISH_ENABLE:-}" == "org-guarded-v1" ]] || fail "publish gate disabled"
[[ "${ARDA_PUBLISH_REPO:-}" == "arda-aaos/arda-aaos-manifest" ]] || fail "target repo not explicitly approved"
for bin in git gh; do command -v "$bin" >/dev/null 2>&1 || fail "required tool missing: $bin"; done
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
[[ "$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null)" == "$ROOT" ]] || fail "unexpected Git root"
[[ "$(git -C "$ROOT" symbolic-ref --short HEAD 2>/dev/null)" == "main" ]] || fail "main branch required"
[[ -z "$(git -C "$ROOT" status --porcelain=v1 --untracked-files=all)" ]] || fail "working tree must be clean; explicitly commit audited changes first"
EXPECTED_URL="https://github.com/arda-aaos/arda-aaos-manifest.git"
[[ "$(git -C "$ROOT" remote get-url origin 2>/dev/null)" == "$EXPECTED_URL" ]] || fail "origin URL mismatch"
[[ "$(git -C "$ROOT" remote get-url --push origin 2>/dev/null)" == "$EXPECTED_URL" ]] || fail "origin pushurl mismatch"
[[ "$(gh api repos/arda-aaos/arda-aaos-manifest --jq .id 2>/dev/null)" == "1291398982" ]] || fail "GitHub repo ID mismatch"
[[ "$(gh api repos/arda-aaos/arda-aaos-manifest --jq .owner.login 2>/dev/null)" == "arda-aaos" ]] || fail "GitHub owner mismatch"
[[ "$(gh api repos/arda-aaos/arda-aaos-manifest --jq .default_branch 2>/dev/null)" == "main" ]] || fail "GitHub default branch mismatch"
[[ "$(gh api repos/arda-aaos/arda-aaos-manifest --jq .private 2>/dev/null)" == "false" ]] || fail "GitHub visibility mismatch"
[[ "$(gh api repos/arda-aaos/arda-aaos-manifest --jq .permissions.admin 2>/dev/null)" == "true" ]] || fail "GitHub admin permission missing"
REMOTE="$(git -C "$ROOT" ls-remote --exit-code origin refs/heads/main 2>/dev/null)" || fail "unable to resolve remote main"
REMOTE_SHA="${REMOTE%%$'\t'*}"
[[ "$REMOTE_SHA" =~ ^[0-9a-f]{40}$ ]] || fail "invalid remote SHA"
[[ "$REMOTE_SHA" == "a85ead3d1d0973e73d7ff34a0cd2d1d67f1ceb0f" ]] || fail "remote baseline moved; re-audit required"
HEAD_SHA="$(git -C "$ROOT" rev-parse HEAD)" || fail "HEAD not found"
[[ "$HEAD_SHA" =~ ^[0-9a-f]{40}$ ]] || fail "invalid HEAD SHA"
[[ "$HEAD_SHA" != "$REMOTE_SHA" ]] || fail "no reviewed new commit to publish"
git -C "$ROOT" merge-base --is-ancestor "$REMOTE_SHA" "$HEAD_SHA" || fail "non-fast-forward commit history"
EXPECTED_CONFIRM="PUBLISH arda-aaos/arda-aaos-manifest FROM ${REMOTE_SHA} TO ${HEAD_SHA}"
[[ "${ARDA_MANIFEST_PUBLISH_CONFIRM:-}" == "$EXPECTED_CONFIRM" ]] || fail "exact SHA confirmation missing"
# This command is NEVER invoked by one-click staging. Explicit externally authorized action only.
git -C "$ROOT" push origin HEAD:refs/heads/main || fail "Git push failed; inspect remote before retry"
echo "ARDA_MANIFEST_GUARDED_PUBLISH=PASS"

#!/usr/bin/env bash
# Deploy amberframework.org to the droplet agentc-agency-01. The droplet NEVER
# compiles; it runs only the bundle the CI workflow exported from the deployment
# image built for the current master HEAD, checked against the sha256 values that
# build recorded.
#
# Usage:
#   scripts/deploy_droplet.sh                    # the successful CI push build of origin/master HEAD
#   scripts/deploy_droplet.sh --branch <name>    # the successful CI build of <name>'s HEAD (e.g. a PR branch)
#   scripts/deploy_droplet.sh --rollback         # repoint `current` to the previous release
#
# Checks, each fatal: a successful CI run exists for exactly the branch HEAD sha;
# release-manifest.json names that sha and branch; sha256 of the bundle and of the
# binary inside it match the manifest here and again on the server; every library
# the binary links resolves on the server. After `current` moves, the site must
# answer 200 through Caddy on /, a docs page and a static asset, or the previous
# release is restored.
#
# Requires: gh (authed), ssh key ~/.ssh/agentc_droplets_id_ed25519.
# Layout on droplet:
#   /srv/site/amberframework/releases/<sha12>-<stamp>/{bin/amberframework,blog,config,docs,public,toolchain-receipts,release-manifest.json}
#   /srv/site/amberframework/current -> releases/<sha12>-<stamp>   (atomic repoint)
#   site-amberframework.service listens on 127.0.0.1:43104; Caddy serves it (deploy/droplet/).
# One-time server setup (user, unit, origin certificate, Caddy site): scripts/setup_droplet.sh.
set -euo pipefail

REPO="crimson-knight/amberframework.org"
DROPLET_IP="161.35.179.248"
DROPLET="root@$DROPLET_IP"
KEY="$HOME/.ssh/agentc_droplets_id_ed25519"
BASE="/srv/site/amberframework"
SVC="site-amberframework"
OWNER="site_amberframework"
SSH_OPTIONS=(-i "$KEY" -o BatchMode=yes -o IdentitiesOnly=yes)

fail() { echo "deploy_droplet: $*" >&2; exit 1; }
sha256_of() { shasum -a 256 "$1" | cut -d' ' -f1; }
manifest_field() { /usr/bin/ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0])).fetch(ARGV[1])' "$1" "$2"; }

# Runs on the server: switch `current` to release $2, restart, and prove the site
# answers through Caddy; on failure restore release $3 (if any) and exit 1.
REMOTE_ACTIVATE='
activate() {
  local base="$1" rel="$2" fallback="$3" svc="$4"
  ln -sfn "$base/releases/$rel" "$base/current.new"
  mv -Tf "$base/current.new" "$base/current"
  systemctl reset-failed "$svc" 2>/dev/null || true
  systemctl restart "$svc"
  local healthy=0
  for attempt in $(seq 1 20); do
    sleep 1
    healthy=1
    for path in / /docs/v2/getting-started/installation /favicon.ico; do
      code=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 10 \
        --resolve amberframework.org:443:127.0.0.1 "https://amberframework.org$path" || true)
      [[ "$code" == "200" ]] || { healthy=0; break; }
    done
    [[ "$healthy" == "1" ]] && break
  done
  if [[ "$healthy" == "1" ]]; then
    echo "server: $svc is $(systemctl is-active "$svc"); /, a docs page and /favicon.ico answer 200 through Caddy on release $rel"
    return 0
  fi
  echo "server: release $rel failed the health check through Caddy" >&2
  if [[ -n "$fallback" ]]; then
    ln -sfn "$base/releases/$fallback" "$base/current.new"
    mv -Tf "$base/current.new" "$base/current"
    systemctl restart "$svc"
    echo "server: restored release $fallback" >&2
  fi
  return 1
}
'

# Prints the remote preamble (strict mode plus activate) and then the script on stdin.
with_activate() { printf "%s\n" "set -euo pipefail" "$REMOTE_ACTIVATE"; cat; }

health_check() {
  echo "Health check from here through Caddy (https, --resolve to the droplet):"
  for path in / /docs/v2/getting-started/installation /favicon.ico; do
    printf '%s %s\n' "$(curl -sk -o /dev/null -w '%{http_code}' --max-time 10 \
      --resolve "amberframework.org:443:$DROPLET_IP" "https://amberframework.org$path")" "$path"
  done
}

BRANCH="master"
EVENT_FLAGS=(--event push)
case "${1:-}" in
  --rollback)
    with_activate << 'REMOTE' | ssh "${SSH_OPTIONS[@]}" "$DROPLET" bash -s -- "$BASE" "$SVC"
BASE="$1"; SVC="$2"
running="$(basename "$(readlink "$BASE/current")")"
previous="$(ls -1dt "$BASE"/releases/*/ | xargs -n1 basename | grep -vxF "$running" | head -1)"
[[ -n "$previous" ]] || { echo "server: no earlier release to roll back to" >&2; exit 1; }
activate "$BASE" "$previous" "$running" "$SVC"
echo "server: rolled back from $running to $previous"
REMOTE
    health_check
    exit 0
    ;;
  --branch)
    BRANCH="${2:-}"
    [[ -n "$BRANCH" ]] || fail "--branch needs a branch name"
    EVENT_FLAGS=()
    ;;
  "") ;;
  *) fail "unknown argument: $1 (use no argument, --branch <name>, or --rollback)" ;;
esac

SHA="$(git ls-remote "https://github.com/$REPO.git" "refs/heads/$BRANCH" | cut -f1)"
[[ "$SHA" =~ ^[0-9a-f]{40}$ ]] || fail "could not read the $BRANCH HEAD sha"
RUN_ID=$(gh run list --repo "$REPO" --workflow CI --commit "$SHA" ${EVENT_FLAGS[@]+"${EVENT_FLAGS[@]}"} \
  --status success --limit 1 --json databaseId --jq '.[0].databaseId')
[[ -n "$RUN_ID" && "$RUN_ID" != "null" ]] \
  || fail "no successful CI build for $BRANCH@${SHA:0:12} yet (still running, or failed): gh run list --repo $REPO --workflow CI --limit 3"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "Fetching CI run $RUN_ID for $BRANCH@${SHA:0:12} ..."
gh run download "$RUN_ID" --repo "$REPO" --name "amberframework-$SHA" --dir "$TMP"
BUNDLE="$TMP/amberframework-bundle.tar.gz"
MANIFEST="$TMP/release-manifest.json"
[[ -f "$BUNDLE" && -f "$MANIFEST" ]] || fail "artifact is missing the bundle or release-manifest.json"

[[ "$(manifest_field "$MANIFEST" git_sha)" == "$SHA" ]] || fail "manifest git_sha differs from $BRANCH HEAD $SHA"
[[ "$(manifest_field "$MANIFEST" git_ref)" == "refs/heads/$BRANCH" ]] || fail "manifest is not from a $BRANCH build"
BUNDLE_SHA256="$(manifest_field "$MANIFEST" bundle_sha256)"
BINARY_SHA256="$(manifest_field "$MANIFEST" binary_sha256)"
[[ "$(sha256_of "$BUNDLE")" == "$BUNDLE_SHA256" ]] || fail "bundle sha256 differs from the manifest"
mkdir "$TMP/binary"
tar xzf "$BUNDLE" -C "$TMP/binary" ./bin/amberframework
[[ "$(sha256_of "$TMP/binary/bin/amberframework")" == "$BINARY_SHA256" ]] || fail "binary sha256 differs from the manifest"
echo "Bundle and binary match the manifest (binary sha256 $BINARY_SHA256)"

REL="${SHA:0:12}-$(date -u +%Y%m%d%H%M%S)"
echo "Uploading $BUNDLE -> $DROPLET:$BASE/releases/$REL"
scp "${SSH_OPTIONS[@]}" "$BUNDLE" "$DROPLET:/tmp/amberframework-bundle.tgz"
scp "${SSH_OPTIONS[@]}" "$MANIFEST" "$DROPLET:/tmp/amberframework-release-manifest.json"

with_activate << 'REMOTE' | ssh "${SSH_OPTIONS[@]}" "$DROPLET" bash -s -- "$BASE" "$REL" "$SVC" "$OWNER" "$BUNDLE_SHA256" "$BINARY_SHA256"
BASE="$1"; REL="$2"; SVC="$3"; OWNER="$4"; BUNDLE_SHA256="$5"; BINARY_SHA256="$6"
[[ "$(sha256sum /tmp/amberframework-bundle.tgz | cut -d' ' -f1)" == "$BUNDLE_SHA256" ]] \
  || { echo "server: uploaded bundle sha256 differs from the manifest" >&2; exit 1; }
mkdir -p "$BASE/releases/$REL"
tar xzf /tmp/amberframework-bundle.tgz -C "$BASE/releases/$REL"
mv /tmp/amberframework-release-manifest.json "$BASE/releases/$REL/release-manifest.json"
rm /tmp/amberframework-bundle.tgz
[[ "$(sha256sum "$BASE/releases/$REL/bin/amberframework" | cut -d' ' -f1)" == "$BINARY_SHA256" ]] \
  || { rm -rf "$BASE/releases/$REL"; echo "server: extracted binary sha256 differs from the manifest" >&2; exit 1; }
if ldd "$BASE/releases/$REL/bin/amberframework" | grep 'not found'; then
  rm -rf "$BASE/releases/$REL"; echo "server: the binary links a library this server lacks" >&2; exit 1
fi
chown -R root:"$OWNER" "$BASE/releases/$REL"
chmod -R u=rwX,g=rX,o= "$BASE/releases/$REL"
chmod 750 "$BASE/releases/$REL/bin/amberframework"
previous=""
[[ -L "$BASE/current" ]] && previous="$(basename "$(readlink "$BASE/current")")"
activate "$BASE" "$REL" "$previous" "$SVC"
# Keep the 5 newest releases; the one `current` points to is never removed.
running="$(basename "$(readlink "$BASE/current")")"
ls -1dt "$BASE"/releases/*/ | tail -n +6 | while IFS= read -r old; do
  [[ "$(basename "$old")" == "$running" ]] || rm -rf "$old"
done
REMOTE

health_check

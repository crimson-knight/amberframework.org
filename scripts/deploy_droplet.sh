#!/usr/bin/env bash
# Deploy amberframework.org to the droplet agentc-agency-01. Only release tags
# deploy (see RELEASING.md). The droplet NEVER compiles; it runs only the bundle
# that CI built and tested for the tag's commit and attached to the tag's GitHub
# Release, checked against the sha256 values that build recorded.
#
# Usage:
#   scripts/deploy_droplet.sh                  # the newest release tag (site-YYYY.MM.N)
#   scripts/deploy_droplet.sh <tag>            # exactly that tag, e.g. site-2026.11.1
#   scripts/deploy_droplet.sh --rollback       # the release tag just before the deployed one
#   add --dry-run to any of these: select and verify the bundle, read what the server
#   runs now, print the plan, and stop before anything is uploaded or changed.
#
# Tag names: site-YYYY.MM.N is a release (N counts from 1 within the month).
# site-YYYY.MM.N-<label> (e.g. site-2026.11.0-test) is a test tag: it deploys only
# when named explicitly, and "newest" and --rollback never pick it.
#
# Checks, each fatal: the argument is a tag of that form and exists on GitHub;
# its Release carries the bundle, release-manifest.json and SHA256SUMS; SHA256SUMS
# matches both files; the manifest names the tag's commit and refs/tags/<tag>; the CI
# run it names passed its verification job for that commit; GitHub's own digest of
# the bundle asset agrees; sha256 of the bundle and of the binary inside it match the
# manifest here and again on the server; every library the binary links resolves on
# the server. After `current` moves, the site must answer 200 through Caddy on /, a
# docs page and a static asset, or the previous release is restored.
#
# Requires: gh (authed), ssh key ~/.ssh/agentc_droplets_id_ed25519.
# Layout on droplet:
#   /srv/site/amberframework/releases/<tag>_<sha12>_<stamp>/{bin/amberframework,blog,config,docs,public,toolchain-receipts,release-manifest.json,DEPLOYED_TAG}
#   /srv/site/amberframework/current -> releases/<tag>_<sha12>_<stamp>   (atomic repoint)
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
VERIFY_JOB="Verify the application and deployment image"
SSH_OPTIONS=(-i "$KEY" -o BatchMode=yes -o IdentitiesOnly=yes)
RELEASE_TAG_PATTERN='^site-[0-9]{4}\.(0[1-9]|1[0-2])\.[0-9]+$'
ANY_TAG_PATTERN='^site-[0-9]{4}\.(0[1-9]|1[0-2])\.[0-9]+(-[0-9A-Za-z.]+)?$'

fail() { echo "deploy_droplet: $*" >&2; exit 1; }
sha256_of() { shasum -a 256 "$1" | cut -d' ' -f1; }
manifest_field() { /usr/bin/ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0])).fetch(ARGV[1])' "$1" "$2"; }

# Reads tag names on stdin and prints them oldest to newest: by year, month and
# number, and a test tag just after the release with the same number.
sort_tags() {
  /usr/bin/ruby -e '
    tags = STDIN.read.split.select { |t| t.match?(/\Asite-\d{4}\.\d{2}\.\d+(-[0-9A-Za-z.]+)?\z/) }
    key = ->(t) { y, m, n, label = t.match(/\Asite-(\d+)\.(\d+)\.(\d+)(?:-(.+))?\z/).captures; [y.to_i, m.to_i, n.to_i, label ? 1 : 0, label.to_s] }
    puts tags.sort_by(&key)'
}

# Prints the release tag immediately before $1 in that order (empty if none).
release_tag_before() {
  /usr/bin/ruby -e '
    key = ->(t) { y, m, n, label = t.match(/\Asite-(\d+)\.(\d+)\.(\d+)(?:-(.+))?\z/).captures; [y.to_i, m.to_i, n.to_i, label ? 1 : 0, label.to_s] }
    current = key.(ARGV[0])
    older = STDIN.read.split.grep(/\Asite-\d{4}\.\d{2}\.\d+\z/).select { |t| (key.(t) <=> current) < 0 }
    puts older.max_by(&key).to_s' "$1"
}

remote_tags() {
  git ls-remote --tags --refs "https://github.com/$REPO.git" 'refs/tags/site-*' | sed 's#.*refs/tags/##'
}

# Prints the release directory and DEPLOYED_TAG the server runs now ("none" if the
# release predates tag deploys). Read only.
server_current() {
  ssh "${SSH_OPTIONS[@]}" "$DROPLET" bash -s -- "$BASE" << 'REMOTE'
BASE="$1"
rel="$(basename "$(readlink "$BASE/current")")"
tag="none"
[[ -f "$BASE/current/DEPLOYED_TAG" ]] && tag="$(head -1 "$BASE/current/DEPLOYED_TAG")"
echo "$rel $tag"
REMOTE
}

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

DRY_RUN=0
MODE="newest"
TAG=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --rollback) [[ "$MODE" == "newest" ]] || fail "give one of: a tag, --rollback, or nothing"; MODE="rollback" ;;
    --*) fail "unknown option: $arg (use <tag>, --rollback, --dry-run)" ;;
    *)
      [[ "$MODE" == "newest" ]] || fail "give one of: a tag, --rollback, or nothing"
      [[ "$arg" =~ $ANY_TAG_PATTERN ]] \
        || fail "'$arg' is not a release tag; only tags named site-YYYY.MM.N (or site-YYYY.MM.N-<label>) deploy. Branches and commits never do."
      MODE="tag"; TAG="$arg"
      ;;
  esac
done

TAGS="$(remote_tags)"
CURRENT_REL="unknown"; CURRENT_TAG="unknown"
if read -r CURRENT_REL CURRENT_TAG < <(server_current 2>/dev/null); then :; else
  [[ "$DRY_RUN" == "1" && "$MODE" != "rollback" ]] || fail "could not read the current release from $DROPLET"
  CURRENT_REL="unknown"; CURRENT_TAG="unknown"
fi
echo "Server runs release $CURRENT_REL (DEPLOYED_TAG: $CURRENT_TAG)"

case "$MODE" in
  newest)
    TAG="$(printf '%s\n' "$TAGS" | grep -E "$RELEASE_TAG_PATTERN" | sort_tags | tail -1 || true)"
    [[ -n "$TAG" ]] || fail "no release tag (site-YYYY.MM.N) exists yet; cut one as RELEASING.md describes"
    echo "Newest release tag: $TAG"
    ;;
  rollback)
    [[ "$CURRENT_TAG" =~ $ANY_TAG_PATTERN ]] \
      || fail "the running release has no DEPLOYED_TAG, so there is no previous tag to compute; deploy a tag by name instead"
    TAG="$(printf '%s\n' "$TAGS" | release_tag_before "$CURRENT_TAG")"
    [[ -n "$TAG" ]] || fail "no release tag older than $CURRENT_TAG exists"
    echo "Rolling back from $CURRENT_TAG to the previous release tag: $TAG"
    ;;
  tag)
    printf '%s\n' "$TAGS" | grep -qxF "$TAG" || fail "tag $TAG does not exist on github.com/$REPO"
    ;;
esac

# The commit the tag points to (peeled, so annotated and lightweight tags agree).
SHA="$(git ls-remote "https://github.com/$REPO.git" "refs/tags/$TAG" "refs/tags/$TAG^{}" \
  | awk '{print $1}' | tail -1)"
[[ "$SHA" =~ ^[0-9a-f]{40}$ ]] || fail "could not read the commit for tag $TAG"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "Fetching the $TAG release assets (commit ${SHA:0:12}) ..."
gh release download "$TAG" --repo "$REPO" --dir "$TMP" \
  --pattern amberframework-bundle.tar.gz --pattern release-manifest.json --pattern SHA256SUMS \
  || fail "tag $TAG has no GitHub Release with the bundle (CI still running, or failed): gh run list --repo $REPO --workflow CI --limit 3"
BUNDLE="$TMP/amberframework-bundle.tar.gz"
MANIFEST="$TMP/release-manifest.json"
[[ -f "$BUNDLE" && -f "$MANIFEST" && -f "$TMP/SHA256SUMS" ]] || fail "release $TAG is missing the bundle, release-manifest.json or SHA256SUMS"

(cd "$TMP" && shasum -a 256 -c SHA256SUMS >/dev/null) || fail "SHA256SUMS of release $TAG does not match its files"
[[ "$(manifest_field "$MANIFEST" git_sha)" == "$SHA" ]] || fail "manifest git_sha differs from the commit tag $TAG points to ($SHA)"
[[ "$(manifest_field "$MANIFEST" git_ref)" == "refs/tags/$TAG" ]] || fail "manifest is not from the CI build of tag $TAG"
RUN_ID="$(manifest_field "$MANIFEST" run_id)"
read -r RUN_SHA RUN_WORKFLOW < <(gh run view "$RUN_ID" --repo "$REPO" --json headSha,workflowName --jq '.headSha + " " + .workflowName')
JOB_RESULT="$(gh run view "$RUN_ID" --repo "$REPO" --json jobs --jq ".jobs[] | select(.name == \"$VERIFY_JOB\") | .conclusion")"
[[ "$RUN_SHA" == "$SHA" && "$RUN_WORKFLOW" == "CI" && "$JOB_RESULT" == "success" ]] \
  || fail "CI run $RUN_ID did not pass '$VERIFY_JOB' for $SHA (sha $RUN_SHA, workflow $RUN_WORKFLOW, result $JOB_RESULT)"
BUNDLE_SHA256="$(manifest_field "$MANIFEST" bundle_sha256)"
BINARY_SHA256="$(manifest_field "$MANIFEST" binary_sha256)"
[[ "$(sha256_of "$BUNDLE")" == "$BUNDLE_SHA256" ]] || fail "bundle sha256 differs from the manifest"
ASSET_DIGEST="$(gh api "repos/$REPO/releases/tags/$TAG" --jq '.assets[] | select(.name == "amberframework-bundle.tar.gz") | .digest // ""')"
[[ -z "$ASSET_DIGEST" || "$ASSET_DIGEST" == "sha256:$BUNDLE_SHA256" ]] || fail "GitHub's digest of the bundle asset ($ASSET_DIGEST) differs from the manifest"
mkdir "$TMP/binary"
tar xzf "$BUNDLE" -C "$TMP/binary" ./bin/amberframework
[[ "$(sha256_of "$TMP/binary/bin/amberframework")" == "$BINARY_SHA256" ]] || fail "binary sha256 differs from the manifest"
echo "Tag $TAG -> commit $SHA; CI run $RUN_ID passed '$VERIFY_JOB'"
echo "SHA256SUMS, GitHub's asset digest${ASSET_DIGEST:+ ($ASSET_DIGEST)} and the manifest agree: bundle sha256 $BUNDLE_SHA256"
echo "Binary matches the manifest: sha256 $BINARY_SHA256"

REL="${TAG}_${SHA:0:12}_$(date -u +%Y%m%d%H%M%S)"
if [[ "$DRY_RUN" == "1" ]]; then
  echo "Dry run: would upload to $DROPLET:$BASE/releases/$REL, write DEPLOYED_TAG=$TAG, and move current from $CURRENT_REL"
  echo "Dry run: nothing was uploaded or changed."
  exit 0
fi

echo "Uploading $TAG -> $DROPLET:$BASE/releases/$REL"
scp "${SSH_OPTIONS[@]}" "$BUNDLE" "$DROPLET:/tmp/amberframework-bundle.tgz"
scp "${SSH_OPTIONS[@]}" "$MANIFEST" "$DROPLET:/tmp/amberframework-release-manifest.json"

with_activate << 'REMOTE' | ssh "${SSH_OPTIONS[@]}" "$DROPLET" bash -s -- "$BASE" "$REL" "$SVC" "$OWNER" "$BUNDLE_SHA256" "$BINARY_SHA256" "$TAG"
BASE="$1"; REL="$2"; SVC="$3"; OWNER="$4"; BUNDLE_SHA256="$5"; BINARY_SHA256="$6"; TAG="$7"
[[ "$(sha256sum /tmp/amberframework-bundle.tgz | cut -d' ' -f1)" == "$BUNDLE_SHA256" ]] \
  || { echo "server: uploaded bundle sha256 differs from the manifest" >&2; exit 1; }
mkdir -p "$BASE/releases/$REL"
tar xzf /tmp/amberframework-bundle.tgz -C "$BASE/releases/$REL"
mv /tmp/amberframework-release-manifest.json "$BASE/releases/$REL/release-manifest.json"
printf '%s\n' "$TAG" > "$BASE/releases/$REL/DEPLOYED_TAG"
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
echo "server: $TAG is live (release $REL)"
# Keep the 5 newest releases; the one `current` points to is never removed.
running="$(basename "$(readlink "$BASE/current")")"
ls -1dt "$BASE"/releases/*/ | tail -n +6 | while IFS= read -r old; do
  [[ "$(basename "$old")" == "$running" ]] || rm -rf "$old"
done
REMOTE

health_check

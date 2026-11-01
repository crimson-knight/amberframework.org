#!/usr/bin/env bash
# One-time (idempotent) server setup for amberframework.org on agentc-agency-01.
# Run from the repository root before the first scripts/deploy_droplet.sh.
#
#   1. system user site_amberframework and /srv/site/amberframework/releases
#   2. the systemd unit deploy/droplet/site-amberframework.service (enabled; it starts on first deploy)
#   3. a Cloudflare Origin CA certificate for amberframework.org and *.amberframework.org
#      (the private key is generated on the server and never leaves it; needs
#      CLOUDFLARE_API_TOKEN with SSL and Certificates edit on the amberframework.org zone)
#   4. the Caddy site deploy/droplet/amberframework.caddy, checked with `caddy validate`
#      and applied with `systemctl reload caddy` (never a restart: other sites share Caddy)
set -euo pipefail

DROPLET="root@161.35.179.248"
KEY="$HOME/.ssh/agentc_droplets_id_ed25519"
SSH_OPTIONS=(-i "$KEY" -o BatchMode=yes -o IdentitiesOnly=yes)
CERT_DIR="/etc/caddy/origin"
CERT_NAME="amberframework-origin"

fail() { echo "setup_droplet: $*" >&2; exit 1; }
remote() { ssh "${SSH_OPTIONS[@]}" "$DROPLET" "$@"; }

[[ -f deploy/droplet/site-amberframework.service && -f deploy/droplet/amberframework.caddy ]] \
  || fail "run from the repository root"

echo "1. user and release directory"
remote bash -s << 'REMOTE'
set -euo pipefail
id site_amberframework >/dev/null 2>&1 \
  || useradd --system --no-create-home --home-dir /srv/site/amberframework --shell /usr/sbin/nologin site_amberframework
install -d -o root -g site_amberframework -m 750 /srv/site/amberframework /srv/site/amberframework/releases
REMOTE

echo "2. systemd unit"
scp "${SSH_OPTIONS[@]}" deploy/droplet/site-amberframework.service "$DROPLET:/etc/systemd/system/site-amberframework.service"
remote 'chmod 644 /etc/systemd/system/site-amberframework.service && systemctl daemon-reload && systemctl enable site-amberframework.service'

echo "3. Cloudflare Origin CA certificate"
if remote "test -s $CERT_DIR/$CERT_NAME.pem -a -s $CERT_DIR/$CERT_NAME.key"; then
  echo "   already present: $CERT_DIR/$CERT_NAME.pem"
else
  [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]] || fail "CLOUDFLARE_API_TOKEN is not set"
  csr="$(remote bash -s -- "$CERT_DIR" "$CERT_NAME" << 'REMOTE'
set -euo pipefail
dir="$1"; name="$2"
umask 077
openssl req -new -newkey rsa:2048 -nodes -keyout "$dir/$name.key.new" \
  -subj "/CN=amberframework.org" -out "$dir/$name.csr" 2>/dev/null
cat "$dir/$name.csr"
REMOTE
)"
  request="$(/usr/bin/ruby -rjson -e 'puts JSON.generate(hostnames: ["amberframework.org", "*.amberframework.org"], requested_validity: 5475, request_type: "origin-rsa", csr: ARGV[0])' "$csr")"
  response="$(curl -s -X POST https://api.cloudflare.com/client/v4/certificates \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json" --data "$request")"
  certificate="$(/usr/bin/ruby -rjson -e 'r = JSON.parse(ARGV[0]); abort(r["errors"].inspect) unless r["success"]; puts r["result"]["certificate"]' "$response")"
  printf '%s\n' "$certificate" | remote "cat > $CERT_DIR/$CERT_NAME.pem.new"
  remote bash -s -- "$CERT_DIR" "$CERT_NAME" << 'REMOTE'
set -euo pipefail
dir="$1"; name="$2"
openssl x509 -in "$dir/$name.pem.new" -noout -subject -enddate
[[ "$(openssl x509 -in "$dir/$name.pem.new" -noout -pubkey | sha256sum)" == "$(openssl pkey -in "$dir/$name.key.new" -pubout | sha256sum)" ]] \
  || { echo "server: certificate does not match the generated key" >&2; exit 1; }
mv "$dir/$name.key.new" "$dir/$name.key"
mv "$dir/$name.pem.new" "$dir/$name.pem"
rm -f "$dir/$name.csr"
chown root:caddy "$dir/$name.key" "$dir/$name.pem"
chmod 640 "$dir/$name.key"
chmod 644 "$dir/$name.pem"
REMOTE
fi

echo "4. Caddy site"
scp "${SSH_OPTIONS[@]}" deploy/droplet/amberframework.caddy "$DROPLET:/etc/caddy/sites/amberframework.caddy.new"
remote bash -s << 'REMOTE'
set -euo pipefail
sites=/etc/caddy/sites
if [[ -f "$sites/amberframework.caddy" ]] && cmp -s "$sites/amberframework.caddy.new" "$sites/amberframework.caddy"; then
  rm "$sites/amberframework.caddy.new"; echo "   unchanged"; exit 0
fi
previous=""
[[ -f "$sites/amberframework.caddy" ]] && { cp "$sites/amberframework.caddy" /root/amberframework.caddy.previous; previous=1; }
mv "$sites/amberframework.caddy.new" "$sites/amberframework.caddy"
chmod 644 "$sites/amberframework.caddy"
if ! caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile; then
  if [[ -n "$previous" ]]; then mv /root/amberframework.caddy.previous "$sites/amberframework.caddy"; else rm "$sites/amberframework.caddy"; fi
  echo "server: caddy validate failed; the site file was not applied" >&2; exit 1
fi
systemctl reload caddy
echo "   caddy reloaded: $(systemctl is-active caddy)"
REMOTE

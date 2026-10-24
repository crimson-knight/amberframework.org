"""Fetch every inventoried route without following redirects; record status and fingerprints."""
import hashlib, http.client, json, re, sys, time, urllib.parse

inventory = json.load(open(sys.argv[1]))
base = urllib.parse.urlparse(sys.argv[2])
delay = float(sys.argv[3]) if len(sys.argv) > 3 else 0.0
UA = "AgentC-Consulting-research/1.0 (+https://agentc.consulting; agent_c@agentc.consulting)"

def normalize(body: bytes) -> bytes:
    text = body.decode("utf-8", "replace")
    text = re.sub(r'(name="_csrf"[^>]*value=")[^"]*', r"\1", text)
    text = re.sub(r'(name="csrf-token"[^>]*content=")[^"]*', r"\1", text)
    text = re.sub(r'<script[^>]*>[^<]*cdn-cgi[^<]*</script>', "", text)
    text = re.sub(r'<script[^>]*src="/cdn-cgi/[^"]*"[^>]*></script>', "", text)
    return text.encode()

results = []
for row in inventory:
    conn_cls = http.client.HTTPSConnection if base.scheme == "https" else http.client.HTTPConnection
    conn = conn_cls(base.netloc, timeout=30)
    path = urllib.parse.quote(row["path"], safe="/.-_~")
    try:
        conn.request(row["method"], path, headers={"User-Agent": UA, "Accept-Encoding": "identity"})
        resp = conn.getresponse()
        body = resp.read()
        results.append({**row, "status": resp.status,
                        "location": resp.getheader("Location", ""),
                        "content_type": (resp.getheader("Content-Type") or "").split(";")[0],
                        "bytes": len(body),
                        "sha256": hashlib.sha256(body).hexdigest(),
                        "normalized_sha256": hashlib.sha256(normalize(body)).hexdigest()})
    except Exception as error:
        results.append({**row, "status": 0, "error": f"{type(error).__name__}: {error}"})
    finally:
        conn.close()
    if delay:
        time.sleep(delay)
json.dump(results, sys.stdout, indent=1)

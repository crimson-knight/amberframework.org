"""Compare two fingerprint files route by route; print a summary and write the full table as JSON."""
import json, sys, collections
a = {(r["method"], r["path"]): r for r in json.load(open(sys.argv[1]))}
b = {(r["method"], r["path"]): r for r in json.load(open(sys.argv[2]))}
rows = []
for key, left in a.items():
    right = b.get(key, {})
    status_same = left.get("status") == right.get("status") and left.get("location") == right.get("location")
    if left.get("sha256") == right.get("sha256"):
        body = "identical"
    elif left.get("normalized_sha256") == right.get("normalized_sha256"):
        body = "identical after normalization"
    else:
        body = "differs"
    rows.append({"method": key[0], "path": key[1], "source": left["source"],
                 "a_status": left.get("status"), "b_status": right.get("status"),
                 "a_location": left.get("location"), "b_location": right.get("location"),
                 "a_bytes": left.get("bytes"), "b_bytes": right.get("bytes"),
                 "status_match": status_same, "body": body})
json.dump(rows, open(sys.argv[3], "w"), indent=1)
print("routes", len(rows))
print("status match", sum(r["status_match"] for r in rows))
print(collections.Counter(r["body"] for r in rows))
for r in rows:
    if not r["status_match"] or r["body"] == "differs":
        print(r["a_status"], r["b_status"], r["a_bytes"], r["b_bytes"], r["body"], r["path"])

"""Build the route inventory for amberframework.org from routes.cr and content."""
import json, re, sys
from pathlib import Path

root = Path(sys.argv[1])
routes_src = (root / "config/routes.cr").read_text()
declared = re.findall(r'^\s*(get|post|websocket)\s+"([^"]+)",\s*([\w:]+)(?:,\s*:(\w+))?', routes_src, re.M)
inventory = []
def add(path, source, method="GET"):
    inventory.append({"method": method, "path": path, "source": source})

for verb, path, controller, action in declared:
    if verb != "get" or ":" in path or "*" in path:
        continue
    add(path, f"routes.cr {controller}#{action}")
    if not path.endswith((".md", ".xml", ".json")) and controller == "HomeController" and path not in ("/",):
        add(path + ".json", f"routes.cr {controller}#{action} (json extension)")
for slug in ("amber", "grant", "gemma"):
    for ext in ("", ".md", ".json"):
        add(f"/characters/{slug}{ext}", "routes.cr /characters/:id")
for post in (root / "blog/posts.yml").read_text().split("\n---"):
    m = re.search(r'^file:\s*(\S+)', post, re.M)
    if m:
        base = "/" + m.group(1)[:-3]
        add(base, "routes.cr /blog/:year/:month/:day/:id (blog/posts.yml)")
        add(base + ".md", "routes.cr /blog/:year/:month/:day/:id (blog/posts.yml)")
for doc in sorted((root / "docs").rglob("*.md")):
    rel = doc.relative_to(root / "docs").as_posix()[:-3]
    if rel.endswith("/index"):
        rel = rel[: -len("/index")]
    elif rel == "index":
        continue
    add(f"/docs/{rel}", "routes.cr /docs/*path (docs/)")
    add(f"/docs/{rel}.md", "routes.cr /docs/*path (docs/, markdown)")
for extra in ("/docs/latest", "/docs/v2", "/docs/v1.5", "/docs/v1.4.1", "/docs/raw/v2/index", "/docs/raw/v2/cli/new",
              "/docs/v2/getting-started.json", "/api/docs/changes/v2", "/api/docs/changes/nope",
              "/guides/getting-started", "/guides", "/amber/guides/routing", "/granite/x", "/recipes/x", "/getting-started/x",
              "/this-route-does-not-exist", "/docs/v2/this-page-does-not-exist", "/mcp"):
    add(extra, "routes.cr redirect/api/error probe")
for f in sorted((root / "public").rglob("*")):
    if f.is_file() and f.name != ".DS_Store":
        add("/" + f.relative_to(root / "public").as_posix(), "routes.cr static /* (public/)")
seen, unique = set(), []
for row in inventory:
    key = (row["method"], row["path"])
    if key not in seen:
        seen.add(key); unique.append(row)
json.dump(unique, sys.stdout, indent=1)

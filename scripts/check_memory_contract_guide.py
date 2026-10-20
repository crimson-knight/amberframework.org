"""Verify the deployed guide's human and agent entry points against its source."""

import argparse
import copy
import hashlib
import json
from pathlib import Path
import re
import sys
from urllib.request import Request, urlopen


GUIDE_PATH = "/docs/v2/guides/memory-contracts"
CANONICAL_URL = "https://amberframework.org" + GUIDE_PATH
MAX_RESPONSE_BYTES = 16 * 1024 * 1024


class VerificationError(Exception):
    pass


def require(condition, message):
    if not condition:
        raise VerificationError(message)


def source_guide():
    source = Path(__file__).resolve().parents[1] / "docs/v2/guides/memory-contracts.md"
    raw = source.read_bytes()
    text = raw.decode("utf-8")
    require(text.startswith("---\n"), "Guide front matter is missing")
    parts = text[4:].split("\n---\n", 1)
    require(len(parts) == 2, "Guide front matter is incomplete")
    metadata = {}
    for key in ("title", "description", "section"):
        match = re.search(r"^" + key + r": (\".*\")$", parts[0], re.MULTILINE)
        require(match is not None, "Guide front matter needs " + key)
        metadata[key] = json.loads(match.group(1))
    body = parts[1].strip()
    require(body.startswith("# " + metadata["title"] + "\n"), "Guide title differs from its body")
    return {**metadata, "body": body, "source_sha256": hashlib.sha256(raw).hexdigest()}


def fetch(base_url, path, payload=None):
    headers = {"Accept": "application/json, text/markdown, text/html", "User-Agent": "AmberDocumentationContract/1.0"}
    data = None
    if payload is not None:
        headers.update({"Content-Type": "application/json", "Mcp-Method": payload["method"]})
        data = json.dumps(payload).encode("utf-8")
    url = base_url + path
    with urlopen(Request(url, data=data, headers=headers), timeout=15) as response:
        require(response.status == 200, "Expected HTTP 200 for " + path)
        require(response.geturl() == url, "Unexpected redirect for " + path)
        raw = response.read(MAX_RESPONSE_BYTES + 1)
        require(len(raw) <= MAX_RESPONSE_BYTES, "Response exceeds the bound for " + path)
        return {"content_type": response.headers.get_content_type(), "body": raw.decode("utf-8")}


def rpc(base_url, request_id, method, params=None):
    payload = {"jsonrpc": "2.0", "id": request_id, "method": method}
    if params is not None:
        payload["params"] = params
    response = fetch(base_url, "/mcp", payload)
    require(response["content_type"] == "application/json", "MCP response needs JSON content type")
    message = json.loads(response["body"])
    require(isinstance(message, dict), "MCP response needs one object")
    require(message.get("jsonrpc") == "2.0" and message.get("id") == request_id, "MCP response identity differs")
    require("error" not in message and isinstance(message.get("result"), dict), "MCP request failed")
    return message["result"]


def tool_text(result):
    require(result.get("isError") is False, "MCP tool reported an error")
    content = result.get("content")
    require(isinstance(content, list) and len(content) == 1, "MCP tool needs one text result")
    require(isinstance(content[0], dict) and content[0].get("type") == "text", "MCP tool result needs text")
    require(isinstance(content[0].get("text"), str), "MCP tool result text is missing")
    return content[0]["text"]


def collect(base_url):
    observed = {key: fetch(base_url, path) for key, path in (
        ("html", GUIDE_PATH), ("markdown", GUIDE_PATH + ".md"),
        ("json", GUIDE_PATH + ".json"), ("bundle", "/docs/v2/knowledge.md"),
    )}
    observed["tools"] = rpc(base_url, 1, "tools/list")
    for request_id, key, name, arguments in (
        (2, "search", "search_docs", {"query": "memory budget contracts"}),
        (3, "read", "read_doc", {"path": "guides/memory-contracts"}),
        (4, "index", "list_docs", {}),
    ):
        observed[key] = rpc(base_url, request_id, "tools/call", {"name": name, "arguments": arguments})
    return observed


def verify(expected, observed):
    body = expected["body"]
    html = observed["html"]
    require(html["content_type"] == "text/html", "Guide HTML needs HTML content type")
    require(expected["title"] in html["body"] and 'href="' + GUIDE_PATH + '"' in html["body"], "Guide HTML title or navigation is missing")
    markdown = observed["markdown"]
    require(markdown["content_type"] == "text/markdown", "Guide Markdown content type differs")
    require(markdown["body"] == body, "Guide Markdown differs from source")
    require(observed["json"]["content_type"] == "application/json", "Guide JSON content type differs")
    page = json.loads(observed["json"]["body"])
    require(isinstance(page, dict), "Guide JSON needs an object")
    for key, value in {
        "title": expected["title"], "description": expected["description"], "section": expected["section"],
        "version": "v2", "path": "guides/memory-contracts", "canonical_url": CANONICAL_URL,
        "markdown_url": CANONICAL_URL + ".md", "content_markdown": body, "inherited": False,
    }.items():
        require(page.get(key) == value, "Guide JSON differs at " + key)
    bundle = observed["bundle"]
    require(bundle["content_type"] == "text/markdown", "Knowledge bundle content type differs")
    require("## " + expected["title"] + "\n\nCanonical page: " + CANONICAL_URL + "\n\n" + body in bundle["body"], "Knowledge bundle guide differs from source")
    tools = observed["tools"].get("tools")
    require(isinstance(tools, list) and all(isinstance(tool, dict) for tool in tools), "MCP tools roster is missing")
    require({"search_docs", "read_doc", "list_docs"}.issubset({tool.get("name") for tool in tools}), "MCP documentation tools are missing")
    link = "[" + expected["title"] + "](" + CANONICAL_URL + ")"
    require(link in tool_text(observed["search"]), "MCP search did not discover the guide")
    require(link in tool_text(observed["index"]), "MCP index did not include the guide")
    require(tool_text(observed["read"]) == "# " + expected["title"] + "\n\nCanonical page: " + CANONICAL_URL + "\n\n" + body, "MCP read differs from source")


def sensitivity_checks(expected, observed):
    controls = []
    for case in ("stale_markdown", "wrong_canonical_url", "mcp_tool_error"):
        changed = copy.deepcopy(observed)
        if case == "stale_markdown":
            changed["markdown"]["body"] += "\nStale guide."
        elif case == "wrong_canonical_url":
            page = json.loads(changed["json"]["body"])
            page["canonical_url"] += "-stale"
            changed["json"]["body"] = json.dumps(page)
        else:
            changed["read"]["isError"] = True
        try:
            verify(expected, changed)
        except VerificationError as error:
            controls.append({"case": case, "rejected": True, "reason": str(error)})
        else:
            raise VerificationError("Sensitivity control was accepted: " + case)
    verify(expected, observed)
    return controls


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", required=True, help="Origin of the running deployment image")
    parser.add_argument("--self-test", action="store_true", help="Challenge the verifier using three changed copies of actual responses")
    args = parser.parse_args()
    expected = source_guide()
    observed = collect(args.base_url.rstrip("/"))
    verify(expected, observed)
    controls = sensitivity_checks(expected, observed) if args.self_test else []
    print(json.dumps({
        "passed": True, "base_url": args.base_url, "canonical_url": CANONICAL_URL,
        "source_sha256": expected["source_sha256"],
        "body_sha256": hashlib.sha256(expected["body"].encode("utf-8")).hexdigest(),
        "verified_entry_points": list(observed), "sensitivity_controls": controls,
    }, indent=2))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(json.dumps({"passed": False, "error": str(error)}), file=sys.stderr)
        sys.exit(1)

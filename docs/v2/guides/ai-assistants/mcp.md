---
title: "Documentation MCP server"
section: "guides"
order: 96
description: "Connect an MCP client to Amber's live, read-only V2 documentation tools"
---

# Documentation MCP server

Amber publishes a remote, read-only Model Context Protocol endpoint at:

```text
https://amberframework.org/mcp
```

The server exposes three tools:

| Tool | Use it for |
|---|---|
| `search_docs` | Find V2 pages by task, concept, API, or filename. |
| `read_doc` | Read one canonical page as Markdown. |
| `list_docs` | List the complete published V2 documentation set. |

The endpoint never writes to an Amber application, repository, account, or
deployment. Tool results point back to canonical public pages so an assistant
can cite the source it used.

## Where the examples go

- The JSON object is MCP client configuration. Add it in the client's server
  settings; do not create it inside an Amber application.
- The `curl` examples run in any terminal and only verify the public endpoint.
  They do not create or modify an application file.
- This guide creates no application source. Do not add the examples to
  `src/`, `config/`, `public/`, `spec/`, or `shard.yml`.

## Add it to an MCP client

**Client configuration — add this as a remote HTTP MCP server, not as an Amber
application file.**

```json
{
  "mcpServers": {
    "amber-docs": {
      "url": "https://amberframework.org/mcp"
    }
  }
}
```

MCP clients use different settings screens and configuration filenames. Keep
the server name and URL above, then follow the client's instructions for adding
a remote HTTP server. No Amber API key or authorization header is required.

## Verify the endpoint directly

**Run from: any terminal; this command does not belong in an Amber project.**

```bash
curl https://amberframework.org/mcp \
  --header 'Content-Type: application/json' \
  --header 'Mcp-Method: tools/list' \
  --data '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

A successful response has `jsonrpc: "2.0"`, the same `id`, and a `result.tools`
array containing `search_docs`, `read_doc`, and `list_docs`.

## Call a documentation tool

**Run from: any terminal.**

```bash
curl https://amberframework.org/mcp \
  --header 'Content-Type: application/json' \
  --header 'Mcp-Method: tools/call' \
  --data '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"search_docs","arguments":{"query":"background job work stealing"}}}'
```

For a specific page, call `read_doc` with a documentation-relative path such
as `guides/websockets` or `/docs/v2/guides/background-jobs`.

## Protocol boundary

The endpoint supports the current stateless `2026-07-28` discovery and tool
methods. It also accepts the legacy `initialize` and
`notifications/initialized` handshake used by 2025 MCP clients. Current clients
can call `server/discover`, `tools/list`, and `tools/call` without creating a
session. The optional `Mcp-Method` request header must match the JSON-RPC method
when supplied.

Because the tool set and public documentation are cacheable, list and discovery
responses include a 15-minute public cache lifetime. Tool calls themselves are
returned with `Cache-Control: no-store` at the HTTP layer.

## Use the other machine-readable formats

MCP is the searchable assistant interface. These simpler public formats remain
useful for scripts and readers:

- add `.md` to a main site, documentation, or blog URL for its Markdown representation;
- add `.json` for structured page, guide, or post data;
- use `/docs/v2/PAGE_PATH.md` for a documentation page's exact Markdown source;
- use `/docs/v2/knowledge.md` for the complete V2 knowledge bundle;
- use `/llms.txt` for the machine-oriented site map;
- use `/blog/feed.xml` or `/rss` for the chronological publication feed.

HTML remains the human browsing representation. JSON is structured data,
Markdown is the readable source representation, RSS is the subscription stream,
and MCP provides discovery plus targeted retrieval. They are complementary,
not aliases for the same job.

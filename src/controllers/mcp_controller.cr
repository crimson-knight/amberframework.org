class McpController < ApplicationController
  PROTOCOL_VERSION = "2026-07-28"
  LEGACY_VERSION   = "2025-11-25"
  SERVER_NAME      = "amber-framework-docs"
  SERVER_VERSION   = "1.0.0"

  def show
    response.status_code = 405
    response.headers["Allow"] = "POST"
    response.content_type = "application/json; charset=utf-8"
    {error: "Use an MCP JSON-RPC POST request at this endpoint."}.to_json
  end

  def handle
    return invalid_origin unless origin_allowed?

    response.content_type = "application/json; charset=utf-8"
    response.headers["Cache-Control"] = "no-store"

    raw = params["_json"]?
    return rpc_error(nil, -32700, "Expected one JSON-RPC request.") unless raw

    message = JSON.parse(raw)
    id = message["id"]?
    method = message["method"]?.try(&.as_s?)
    return rpc_error(id, -32600, "Invalid JSON-RPC request.") unless method

    if declared_method = request.headers["Mcp-Method"]?
      return rpc_error(id, -32600, "Mcp-Method header does not match the JSON-RPC method.") unless declared_method == method
    end

    case method
    when "server/discover"
      rpc_result(id, {
        resultType:        "complete",
        supportedVersions: [PROTOCOL_VERSION],
        capabilities:      {tools: {} of String => String},
        serverInfo:        {name: SERVER_NAME, version: SERVER_VERSION},
        instructions:      "Search the canonical Amber V2 documentation before answering, then read the exact page and preserve every file-placement instruction and beta boundary.",
        ttlMs:             900_000,
        cacheScope:        "public",
      })
    when "initialize"
      requested = message["params"]?.try(&.["protocolVersion"]?).try(&.as_s?) || LEGACY_VERSION
      selected = requested == PROTOCOL_VERSION ? LEGACY_VERSION : requested
      rpc_result(id, {
        protocolVersion: selected,
        capabilities:    {tools: {listChanged: false}},
        serverInfo:      {name: SERVER_NAME, version: SERVER_VERSION},
        instructions:    "Use search_docs, then read_doc. Cite the canonical page returned by the tool.",
      })
    when "notifications/initialized"
      response.status_code = 202
      ""
    when "tools/list"
      rpc_result(id, {
        tools:      tool_definitions,
        ttlMs:      900_000,
        cacheScope: "public",
      })
    when "tools/call"
      call_tool(id, message)
    else
      rpc_error(id, -32601, "Method not found: #{method}")
    end
  rescue JSON::ParseException
    rpc_error(nil, -32700, "Invalid JSON.")
  end

  private def call_tool(id, message : JSON::Any)
    tool_params = message["params"]?
    name = tool_params.try(&.["name"]?).try(&.as_s?)
    arguments = tool_params.try(&.["arguments"]?).try(&.as_h?) || {} of String => JSON::Any

    case name
    when "search_docs"
      query = arguments["query"]?.try(&.as_s?).to_s.strip
      return rpc_result(id, tool_result("`query` must be a non-empty string.", true)) if query.empty?
      rpc_result(id, tool_result(search_docs(query)))
    when "read_doc"
      path = arguments["path"]?.try(&.as_s?).to_s.strip
      return rpc_result(id, tool_result("`path` must be a V2 documentation path.", true)) if path.empty?
      if page = find_doc(path)
        canonical = "https://amberframework.org/docs/#{page.url_path}"
        rpc_result(id, tool_result("# #{page.title}\n\nCanonical page: #{canonical}\n\n#{page.content}"))
      else
        rpc_result(id, tool_result("No Amber V2 documentation page matched `#{path}`.", true))
      end
    when "list_docs"
      index = DocsScanner.scan_version("v2").map do |page|
        "- [#{page.title}](https://amberframework.org/docs/#{page.url_path}) — #{page.description}"
      end.join("\n")
      rpc_result(id, tool_result("# Amber V2 documentation\n\n#{index}"))
    else
      rpc_error(id, -32602, "Unknown tool: #{name || "<missing>"}")
    end
  end

  private def search_docs(query : String) : String
    terms = query.downcase.split.reject(&.empty?)
    matches = DocsScanner.scan_version("v2").compact_map do |page|
      title = page.title.downcase
      description = page.description.downcase
      content = page.content.downcase
      score = terms.sum do |term|
        (title.includes?(term) ? 6 : 0) +
          (description.includes?(term) ? 3 : 0) +
          (content.includes?(term) ? 1 : 0)
      end
      score > 0 ? {page, score} : nil
    end.sort_by { |entry| {-entry[1], entry[0].title} }.first(8)

    return "No Amber V2 documentation matched `#{query}`." if matches.empty?

    String.build do |text|
      text << "# Amber V2 documentation results for: #{query}\n\n"
      matches.each do |page, _score|
        text << "- [#{page.title}](https://amberframework.org/docs/#{page.url_path}) — #{page.description}\n"
      end
    end
  end

  private def find_doc(path : String) : DocPage?
    normalized = path
      .sub(/^https?:\/\/amberframework\.org\/docs\//, "")
      .sub(/^\/docs\//, "")
      .sub(/^v2\//, "")
      .sub(/\.md$/, "")
      .strip("/")
    DocsScanner.find_page("v2", normalized)
  end

  private def tool_result(text : String, is_error : Bool = false)
    {content: [{type: "text", text: text}], isError: is_error}
  end

  private def tool_definitions
    [
      {
        name:        "search_docs",
        title:       "Search Amber V2 documentation",
        description: "Search canonical Amber V2 guides by concept, API, filename, or task.",
        inputSchema: {
          type:                 "object",
          properties:           {query: {type: "string", description: "What to find in the Amber V2 documentation."}},
          required:             ["query"],
          additionalProperties: false,
        },
        annotations: {readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false},
      },
      {
        name:        "read_doc",
        title:       "Read an Amber V2 documentation page",
        description: "Return the canonical Markdown source and URL for one Amber V2 documentation path.",
        inputSchema: {
          type:                 "object",
          properties:           {path: {type: "string", description: "A path such as guides/websockets or /docs/v2/guides/websockets."}},
          required:             ["path"],
          additionalProperties: false,
        },
        annotations: {readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false},
      },
      {
        name:        "list_docs",
        title:       "List Amber V2 documentation",
        description: "Return the complete canonical V2 documentation index.",
        inputSchema: {type: "object", properties: {} of String => String, additionalProperties: false},
        annotations: {readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false},
      },
    ]
  end

  private def rpc_result(id, result)
    {jsonrpc: "2.0", id: id, result: result}.to_json
  end

  private def rpc_error(id, code : Int32, message : String)
    {jsonrpc: "2.0", id: id, error: {code: code, message: message}}.to_json
  end

  private def origin_allowed? : Bool
    origin = request.headers["Origin"]?
    return true unless origin
    origin == "https://amberframework.org" || origin.starts_with?("http://127.0.0.1:") || origin.starts_with?("http://localhost:")
  end

  private def invalid_origin
    response.status_code = 403
    response.content_type = "application/json; charset=utf-8"
    rpc_error(nil, -32000, "Origin is not allowed.")
  end
end

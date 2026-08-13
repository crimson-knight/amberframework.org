require "markd"

# Service to preprocess markdown content, converting GitBook-specific syntax to HTML

module MarkdownPreprocessor
  extend self

  # Process markdown content, converting GitBook syntax to HTML
  def process(content : String, *, version_id : String? = nil, page_path : String? = nil) : String
    result = content
    # Rewrite links before rendering GitBook hint or tab bodies to HTML. Once a
    # body is HTML, a Markdown-only rewrite can no longer see its links.
    result = fix_internal_links(result, version_id, page_path)
    result = convert_hints(result)
    result = convert_code_tabs(result)
    result = convert_page_refs(result, version_id, page_path)
    result = fix_asset_paths(result)
    result
  end

  # Render site Markdown with GitHub Flavored Markdown enabled so the tables
  # used throughout the versioned guides become semantic HTML tables.
  def render(content : String, *, preprocess : Bool = true, safe : Bool = false, version_id : String? = nil, page_path : String? = nil) : String
    source = preprocess ? process(content, version_id: version_id, page_path: page_path) : content
    options = Markd::Options.new(gfm: true, safe: safe)
    enhance_html(Markd.to_html(source, options))
  end

  # Add presentation wrappers after Markdown has been rendered. The wrapper
  # keeps table semantics intact while providing an overflow region, and gives
  # code samples a local editor or terminal component based on what the sample
  # actually represents.
  def enhance_html(html : String) : String
    result = wrap_tables(html)
    wrap_code_windows(result)
  end

  private def wrap_tables(html : String) : String
    html.gsub(/(<table(?:\s[^>]*)?>.*?<\/table>)/m) do
      %(<div class="table-scroll" role="region" aria-label="Scrollable documentation table" tabindex="0">#{$1}</div>)
    end
  end

  private def wrap_code_windows(html : String) : String
    html.gsub(/<pre><code(?: class="language-([^"]+)")?>(.*?)<\/code><\/pre>/m) do
      code = $2
      source_language = $~[1]?
      language = normalize_code_language(source_language, code)
      terminal = {"bash", "console", "shell", "sh", "zsh", "powershell", "pwsh"}.includes?(language)
      kind = terminal ? "terminal" : "editor"
      label = code_label(language, terminal)

      %(<div class="code-window code-window-#{kind}" data-code-kind="#{kind}"><div class="code-window-toolbar"><span class="code-window-language">#{label}</span></div><pre><code class="language-#{language}">#{code}</code></pre></div>)
    end
  end

  private def normalize_code_language(language : String?, code : String) : String
    normalized = language.to_s.downcase

    case normalized
    when "ruby", "cr"
      "crystal"
    when "yml"
      "yaml"
    when "js"
      "javascript"
    when "html+ecr"
      "ecr"
    when "text", "plaintext", "txt"
      file_tree?(code) ? "tree" : "output"
    when ""
      infer_untyped_language(code)
    else
      normalized
    end
  end

  private def infer_untyped_language(code : String) : String
    return "tree" if file_tree?(code)
    return "crystal" if code.includes?("Amber::") || code.matches?(/\b(class|module|def|require)\s+[A-Za-z]/)
    return "yaml" if code.lines.reject(&.strip.empty?).all? { |line| line.matches?(/^\s*[A-Za-z_][\w.-]*:\s*[^:]*/) }
    return "ecr" if code.includes?("&lt;%")
    return "html" if code.lstrip.starts_with?("&lt;")

    "example"
  end

  private def file_tree?(code : String) : Bool
    code.includes?("├──") || code.includes?("└──") || code.includes?("│")
  end

  private def code_label(language : String, terminal : Bool) : String
    return "Terminal" if terminal

    {
      "crystal"    => "Crystal",
      "yaml"       => "YAML",
      "json"       => "JSON",
      "ecr"        => "ECR template",
      "html"       => "HTML",
      "css"        => "CSS",
      "javascript" => "JavaScript",
      "markdown"   => "Markdown",
      "md"         => "Markdown",
      "sql"        => "SQL",
      "toml"       => "TOML",
      "tree"       => "File tree",
      "output"     => "Output",
      "example"    => "Example",
    }[language]? || language.capitalize
  end

  # Convert {% hint style="info" %}content{% endhint %} to styled divs
  private def convert_hints(content : String) : String
    # Match hint blocks (multiline)
    content.gsub(/{%\s*hint\s+style="(\w+)"\s*%}(.*?){%\s*endhint\s*%}/m) do |match|
      style = $1
      inner = $2.strip

      # Process the inner content as markdown
      inner_html = Markd.to_html(inner, Markd::Options.new(gfm: true))

      %(<div class="hint hint-#{style}">#{inner_html}</div>)
    end
  end

  # Convert {% code-tabs %}...{% endcode-tabs %} to titled code blocks
  private def convert_code_tabs(content : String) : String
    # Match code-tabs blocks
    content.gsub(/{%\s*code-tabs\s*%}(.*?){%\s*endcode-tabs\s*%}/m) do |match|
      inner = $1

      # Extract code-tabs-items
      result = inner.gsub(/{%\s*code-tabs-item\s+title="([^"]+)"\s*%}(.*?){%\s*endcode-tabs-item\s*%}/m) do |item_match|
        title = $1.gsub("\\_", "_") # Unescape underscores
        code = $2.strip
        rendered_code = Markd.to_html(code, Markd::Options.new(gfm: true))

        %(<div class="code-block-titled"><div class="code-title">#{title}</div>\n#{rendered_code}\n</div>)
      end

      result
    end
  end

  # Convert {% page-ref page="path" %} to markdown links
  private def convert_page_refs(content : String, version_id : String?, page_path : String?) : String
    content.gsub(/{%\s*page-ref\s+page="([^"]+)"\s*%}/m) do |match|
      path = $1
      destination = documentation_path(path, version_id, page_path)
      label = path.sub(/\.md$/, "").sub(/README$/, "").strip("/").split("/").last

      # Create a link
      %(<p class="page-ref"><a href="#{destination}">Continue reading: #{label}</a></p>)
    end
  end

  # Fix internal markdown links to use /docs/ URLs
  private def fix_internal_links(content : String, version_id : String?, page_path : String?) : String
    # Match Markdown document links and directory index links. Assets, anchors,
    # downloads, and external URLs are intentionally left alone.
    content.gsub(/\[([^\]]+)\]\(([^)]+(?:\.md(?:#[^)]+)?|\/))\)/) do |match|
      link_text = $1
      path = $2

      # Skip external links
      if path.starts_with?("http://") || path.starts_with?("https://")
        match
      else
        "[#{link_text}](#{documentation_path(path, version_id, page_path)})"
      end
    end
  end

  # Resolve a Markdown page from the current guide instead of flattening every
  # relative link to the documentation root. Versioned pages must keep readers
  # inside the version they intentionally selected.
  private def documentation_path(path : String, version_id : String?, page_path : String?) : String
    path_and_anchor = path.split("#", 2)
    relative_path = path_and_anchor[0]
    anchor = path_and_anchor[1]?

    segments = [] of String
    unless relative_path.starts_with?("/")
      current_segments = page_path.to_s.strip("/").split("/")
      current_segments.pop unless current_segments.empty?
      segments.concat(current_segments)
    end

    relative_path
      .sub(/\.md$/, "")
      .sub(/README$/, "")
      .sub(/\/?index$/, "")
      .strip("/")
      .split("/")
      .each do |segment|
        case segment
        when "", "."
          next
        when ".."
          segments.pop unless segments.empty?
        else
          segments << segment
        end
      end

    version_prefix = version_id ? "/docs/#{version_id}" : "/docs"
    destination = segments.empty? ? version_prefix : "#{version_prefix}/#{segments.join("/")}"
    anchor ? "#{destination}##{anchor}" : destination
  end

  # Fix asset paths to use /docs/assets/
  private def fix_asset_paths(content : String) : String
    # Fix .gitbook/assets/ references
    content
      .gsub(/\(\.gitbook\/assets\//, "(/docs/assets/")
      .gsub(/\(\.\.\/\.gitbook\/assets\//, "(/docs/assets/")
      .gsub(/\(assets\//, "(/docs/assets/")
  end
end

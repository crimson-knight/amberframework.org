require "markd"

# Service to preprocess markdown content, converting GitBook-specific syntax to HTML

module MarkdownPreprocessor
  extend self

  # Process markdown content, converting GitBook syntax to HTML
  def process(content : String) : String
    result = content
    result = convert_hints(result)
    result = convert_code_tabs(result)
    result = convert_page_refs(result)
    result = fix_internal_links(result)
    result = fix_asset_paths(result)
    result
  end

  # Render site Markdown with GitHub Flavored Markdown enabled so the tables
  # used throughout the versioned guides become semantic HTML tables.
  def render(content : String, *, preprocess : Bool = true) : String
    source = preprocess ? process(content) : content
    options = Markd::Options.new(gfm: true)
    enhance_html(Markd.to_html(source, options))
  end

  # Add presentation wrappers after Markdown has been rendered. The wrapper
  # keeps table semantics intact while providing an overflow region, and gives
  # every code sample the same local terminal-window component.
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
      language = $~[1]? || "code"
      label = {"bash", "console", "shell", "sh", "zsh"}.includes?(language) ? "terminal" : language
      code = $2

      %(<div class="code-window"><div class="code-window-toolbar"><span class="code-window-language">#{label}</span></div><pre><code class="language-#{language}">#{code}</code></pre></div>)
    end
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

        %(<div class="code-block-titled"><div class="code-title">#{title}</div>\n#{code}\n</div>)
      end

      result
    end
  end

  # Convert {% page-ref page="path" %} to markdown links
  private def convert_page_refs(content : String) : String
    content.gsub(/{%\s*page-ref\s+page="([^"]+)"\s*%}/m) do |match|
      path = $1
        .sub(/\.md$/, "")
        .sub(/^\.\.\//, "")
        .sub(/^\.\//, "")
        .sub(/README$/, "")
        .strip("/")

      # Create a link
      %(<p class="page-ref"><a href="/docs/#{path}">Continue reading: #{path.split("/").last}</a></p>)
    end
  end

  # Fix internal markdown links to use /docs/ URLs
  private def fix_internal_links(content : String) : String
    # Match markdown links that end with .md
    content.gsub(/\[([^\]]+)\]\(([^)]+\.md)\)/) do |match|
      link_text = $1
      path = $2

      # Skip external links
      if path.starts_with?("http://") || path.starts_with?("https://")
        match
      else
        # Convert relative path to absolute /docs/ URL
        clean_path = path
          .sub(/\.md$/, "")
          .sub(/README$/, "")
          .sub(/^\.\.\//, "")
          .sub(/^\.\//, "")
          .strip("/")

        "[#{link_text}](/docs/#{clean_path})"
      end
    end
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

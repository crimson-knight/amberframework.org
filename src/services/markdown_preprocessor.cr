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

  # Convert {% hint style="info" %}content{% endhint %} to styled divs
  private def convert_hints(content : String) : String
    # Match hint blocks (multiline)
    content.gsub(/{%\s*hint\s+style="(\w+)"\s*%}(.*?){%\s*endhint\s*%}/m) do |match|
      style = $1
      inner = $2.strip

      # Process the inner content as markdown
      inner_html = Markd.to_html(inner)

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
        title = $1.gsub("\\_", "_")  # Unescape underscores
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

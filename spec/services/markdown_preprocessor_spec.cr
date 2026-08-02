require "../spec_helper"

describe MarkdownPreprocessor do
  describe ".enhance_html" do
    it "keeps table semantics inside an accessible overflow wrapper" do
      html = <<-HTML
      <table><thead><tr><th>Platform</th></tr></thead><tbody><tr><td>Linux</td></tr></tbody></table>
      HTML

      enhanced = MarkdownPreprocessor.enhance_html(html)
      enhanced.should contain(%(class="table-scroll"))
      enhanced.should contain(%(role="region"))
      enhanced.should contain("<table>")
      enhanced.should contain("<th>Platform</th>")
    end

    it "wraps shell samples in the shared terminal-window component" do
      html = %(<pre><code class="language-bash">amber new my_app\n</code></pre>)

      enhanced = MarkdownPreprocessor.enhance_html(html)
      enhanced.should contain(%(class="code-window"))
      enhanced.should contain(%(class="code-window-language">terminal</span>))
      enhanced.should contain("amber new my_app")
    end

    it "labels untyped samples as code" do
      html = %(<pre><code>Amber::Server.start\n</code></pre>)

      enhanced = MarkdownPreprocessor.enhance_html(html)
      enhanced.should contain(%(class="code-window-language">code</span>))
      enhanced.should contain(%(class="language-code"))
    end

    it "renders every beta-support table inside the safety wrapper" do
      markdown = File.read("docs/v2/beta-support.md")
      html = MarkdownPreprocessor.render(markdown)

      table_count = html.scan(/<table>/).size
      wrapper_count = html.scan(/class="table-scroll"/).size
      table_count.should be > 0
      wrapper_count.should eq(table_count)
    end
  end

  describe ".process" do
    it "keeps relative guide links inside the selected documentation version" do
      markdown = "Read the [installation guide](../installation.md) and [session details](sessions.md#flash)."
      processed = MarkdownPreprocessor.process(
        markdown,
        version_id: "v2",
        page_path: "guides/controllers/request-and-response-objects"
      )

      processed.should contain("[installation guide](/docs/v2/guides/installation)")
      processed.should contain("[session details](/docs/v2/guides/controllers/sessions#flash)")
    end

    it "keeps GitBook page references inside the selected documentation version" do
      markdown = %({% page-ref page="../guides/installation.md" %})
      processed = MarkdownPreprocessor.process(
        markdown,
        version_id: "v2",
        page_path: "getting-started/index"
      )

      processed.should contain(%(href="/docs/v2/guides/installation"))
    end

    it "rewrites links before rendering GitBook hints" do
      markdown = <<-MARKDOWN
      {% hint style="warning" %}
      Use [Amber CLI](../guides/create-new-app.md) or read the [CLI index](../cli/).
      {% endhint %}
      MARKDOWN
      html = MarkdownPreprocessor.render(
        markdown,
        version_id: "v2",
        page_path: "cookbook/file-download"
      )

      html.should contain(%(href="/docs/v2/guides/create-new-app"))
      html.should contain(%(href="/docs/v2/cli"))
    end

    it "renders GitBook code tabs without swallowing following content" do
      markdown = <<-MARKDOWN
      {% code-tabs %}
      {% code-tabs-item title="config/application.cr" %}
      ```ruby
      Amber::Server.configure do |app|
      end
      ```
      {% endcode-tabs-item %}
      {% endcode-tabs %}

      Also see [pipelines](../guides/routing/pipelines.md).
      MARKDOWN
      html = MarkdownPreprocessor.render(
        markdown,
        version_id: "v2",
        page_path: "cookbook/file-download"
      )

      html.should contain(%(class="code-window-language">ruby</span>))
      html.should contain("Amber::Server.configure")
      html.should contain(%(href="/docs/v2/guides/routing/pipelines"))
      html.should_not contain("```")
    end
  end

  describe "V2 authored links" do
    it "resolves every versioned Markdown page target" do
      Dir.glob("docs/v2/**/*.md").each do |source_path|
        source_page_path = source_path
          .sub(/^docs\/v2\//, "")
          .sub(/\.md$/, "")

        html = MarkdownPreprocessor.render(
          File.read(source_path),
          version_id: "v2",
          page_path: source_page_path
        )

        html.scan(/href="\/docs\/v2\/([^"#?]+)/).each do |match|
          target = match[1].strip("/")
          DocsScanner.find_page("v2", target).should_not be_nil,
            "#{source_path} links to missing V2 page #{target}"
        end
      end
    end

    it "does not render third-party documentation images" do
      DocsScanner.scan_version("v2").each do |page|
        source_page_path = page.relative_path.sub(/\.md$/, "")
        html = MarkdownPreprocessor.render(
          page.content,
          version_id: "v2",
          page_path: source_page_path
        )

        html.should_not match(/<img[^>]+src="https?:\/\//i),
          "#{page.relative_path} renders a third-party image"
      end
    end
  end
end

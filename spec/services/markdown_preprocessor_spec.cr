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
      enhanced.should contain(%(class="code-window code-window-terminal"))
      enhanced.should contain(%(class="code-window-language">Terminal</span>))
      enhanced.should contain("amber new my_app")
    end

    it "renders untyped Crystal as an editor instead of a terminal" do
      html = %(<pre><code>Amber::Server.start\n</code></pre>)

      enhanced = MarkdownPreprocessor.enhance_html(html)
      enhanced.should contain(%(class="code-window code-window-editor"))
      enhanced.should contain(%(class="code-window-language">Crystal</span>))
      enhanced.should contain(%(class="language-crystal"))
    end

    it "renders configuration and file trees with editor labels" do
      yaml = %(<pre><code class="language-yaml">server:\n  port: 3000\n</code></pre>)
      tree = %(<pre><code class="language-text">my_app/\n└── shard.yml\n</code></pre>)

      MarkdownPreprocessor.enhance_html(yaml).should contain(%(class="code-window-language">YAML</span>))
      MarkdownPreprocessor.enhance_html(tree).should contain(%(class="code-window-language">File tree</span>))
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

      html.should contain(%(class="code-window-language">Crystal</span>))
      html.should contain(%(class="language-crystal"))
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
          next if target == "knowledge.md"
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

  describe "V2 guide clarity" do
    it "gives every audited example a file, command location, or output role" do
      audited_guides = [
        "docs/v2/guides/adapters/index.md",
        "docs/v2/guides/adapters/pubsub.md",
        "docs/v2/guides/adapters/sessions.md",
        "docs/v2/guides/assets/configuration.md",
        "docs/v2/guides/assets/import-maps.md",
        "docs/v2/guides/assets/index.md",
        "docs/v2/guides/assets/stimulus.md",
        "docs/v2/guides/controllers/halt.md",
        "docs/v2/guides/controllers/index.md",
        "docs/v2/guides/controllers/request-and-response-objects.md",
        "docs/v2/guides/controllers/respond-with.md",
        "docs/v2/guides/controllers/sessions.md",
        "docs/v2/guides/mailers/index.md",
        "docs/v2/guides/native-preview/index.md",
        "docs/v2/guides/routing/pipelines.md",
        "docs/v2/guides/routing/routes.md",
        "docs/v2/guides/views/index.md",
        "docs/v2/guides/web-template/index.md",
        "docs/v2/guides/websockets/sockets.md",
      ]
      placement_marker = /\*\*(File|Files|Run from|Reference|Generated output|Generated files|Expected browser output)/

      audited_guides.each do |path|
        lines = File.read_lines(path)
        inside_fence = false

        lines.each_with_index do |line, index|
          next unless line.starts_with?("```")

          unless inside_fence
            context_start = {index - 8, 0}.max
            context = lines[context_start...index].join("\n")

            context.should match(placement_marker),
              "#{path}:#{index + 1} needs an explicit file, run location, reference, or output label"
          end

          inside_fence = !inside_fence
        end

        inside_fence.should be_false, "#{path} contains an unclosed code fence"
      end
    end

    it "gives every code-bearing guide a local label or a page-level file map" do
      placement_marker = /\*\*(File|Files|Run from|Reference|Generated output|Generated files|Expected browser output)/

      Dir.glob("docs/v2/guides/**/*.md").each do |path|
        lines = File.read_lines(path)
        inside_fence = false
        unlabeled_fences = 0

        lines.each_with_index do |line, index|
          next unless line.starts_with?("```")

          unless inside_fence
            context_start = {index - 8, 0}.max
            context = lines[context_start...index].join("\n")
            unlabeled_fences += 1 unless context.matches?(placement_marker)
          end

          inside_fence = !inside_fence
        end

        next if unlabeled_fences == 0

        content = lines.join("\n")
        content.should contain("## Where the examples go"),
          "#{path} has #{unlabeled_fences} examples without local placement labels and needs a page-level file map"
        content.should match(/`(?:config|public|shard\.yml|spec|src)[^`]*`/),
          "#{path} has a placement section but does not name an application path"
      end
    end
  end
end

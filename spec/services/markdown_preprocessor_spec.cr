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
end

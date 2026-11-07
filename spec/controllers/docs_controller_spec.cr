require "./spec_helper"
require "../../src/controllers/application_controller"
require "../../src/controllers/docs_controller"

private def rendered_docs_page(path : String) : String
  response = HTTP::Server::Response.new(IO::Memory.new)
  context = HTTP::Server::Context.new(HTTP::Request.new("GET", path), response)
  context.params["path"] = path.sub("/docs/", "")
  DocsController.new(context).show.to_s
end

describe DocsController do
  describe "#show" do
    it "renders section ids, a versioned title and TechArticle JSON-LD" do
      html = rendered_docs_page("/docs/v2/getting-started/installation")

      html.should contain("<title>Installation — Amber 2.0 Web Beta documentation</title>")
      html.should contain(%(<link rel="canonical" href="https://amberframework.org/docs/v2/getting-started/installation">))
      html.should contain(%("@type":"TechArticle"))
      html.should contain(%("url":"https://amberframework.org/docs/v2/getting-started/installation"))
      html.should match(/<h2 id="[a-z0-9-]+">.*?<a class="heading-anchor" href="#/)
    end

    it "describes an inherited page that has no front-matter description" do
      html = rendered_docs_page("/docs/v1.5/guides/controllers")

      html.should contain(%(<meta name="description" content="Controllers in the Amber Framework 1.5 Stable documentation.">))
      html.should contain(%("description":"Controllers in the Amber Framework 1.5 Stable documentation."))
    end
  end
end

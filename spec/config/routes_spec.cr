require "../spec_helper"
require "../../config/application"
require "../../config/routes"

# The site serves a Markdown edition of its pages at "<page>.md". Some pages
# declare that address as its own route; the rest reach their HTML route, whose
# action answers in Markdown for a ".md" path. These examples pin which action
# each kind of address reaches through the real route table.
private def routed_action(path : String) : String
  result = Amber::Server.router.match("GET", path)
  route = result.payload?
  return "not found" unless result.found? && route
  "#{route.controller}##{route.action}"
end

describe "config/routes.cr" do
  it "sends a declared .md address to the route that declares it" do
    routed_action("/pioneers.md").should eq("Publication::ServePublicPageController#pioneers")
    routed_action("/index.md").should eq("HomeController#page_markdown")
    routed_action("/releases.md").should eq("HomeController#page_markdown")
    routed_action("/blog.md").should eq("BlogController#index_markdown")
    routed_action("/docs/v2/knowledge.md").should eq("DocsController#knowledge")
  end

  it "sends an undeclared .md address to the page route without the extension" do
    routed_action("/blog/2026/08/13/amber-v2-router-on-a-four-dollar-droplet.md").should eq("BlogController#show")
    routed_action("/docs/v2/getting-started/installation.md").should eq("DocsController#show")
  end

  it "keeps the HTML addresses on their page routes" do
    routed_action("/").should eq("HomeController#index")
    routed_action("/pioneers").should eq("Publication::ServePublicPageController#pioneers")
    routed_action("/blog").should eq("BlogController#index")
  end
end

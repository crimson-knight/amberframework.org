require "../../spec_helper"
require "../../../src/controllers/application_controller"
require "../../../src/controllers/publication/serve_public_page_controller"

describe Publication::ServePublicPageController do
  it "serves HTML by default and gives extension requests their selected representation" do
    {"/pioneers"      => {"text/html", "Seek adventure"},
     "/pioneers.md"   => {"text/markdown; charset=utf-8", "#"},
     "/pioneers.json" => {"application/json; charset=utf-8", "schema_version"}}.each do |path, expected|
      response = HTTP::Server::Response.new(IO::Memory.new)
      context = HTTP::Server::Context.new(HTTP::Request.new("GET", path), response)
      controller = Publication::ServePublicPageController.new(context)
      controller.pioneers
      response.status_code.should eq(200)
      response.content_type.should eq(expected[0])
      context.content.to_s.should contain(expected[1])
    end
  end

  it "rejects a representation the publication does not provide" do
    response = HTTP::Server::Response.new(IO::Memory.new)
    headers = HTTP::Headers{"Accept" => "application/xml"}
    context = HTTP::Server::Context.new(HTTP::Request.new("GET", "/pioneers", headers), response)
    Publication::ServePublicPageController.new(context).pioneers
    response.status_code.should eq(406)
    context.content.should eq("Response Not Acceptable.")
  end
end

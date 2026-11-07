require "./spec_helper"
require "../../src/controllers/application_controller"
require "../../src/controllers/sitemap_controller"

describe SitemapController do
  describe "#show" do
    it "serves the generated sitemap as cacheable XML" do
      response = HTTP::Server::Response.new(IO::Memory.new)
      context = HTTP::Server::Context.new(HTTP::Request.new("GET", "/sitemap.xml"), response)

      body = SitemapController.new(context).show

      response.content_type.should eq("application/xml; charset=utf-8")
      response.headers["Cache-Control"].should eq("public, max-age=3600")
      body.should start_with(%(<?xml version="1.0" encoding="UTF-8"?>))
      body.should contain("<loc>https://amberframework.org/docs/v2</loc>")
      body.should contain("<loc>https://amberframework.org/performance</loc>")
    end
  end
end

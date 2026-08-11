require "html"

class BlogController < ApplicationController
  SITE_URL = "https://amberframework.org"
  @posts = YAML.parse_all File.read("blog/posts.yml")

  def index
    return index_json if request.path.ends_with?(".json")
    return index_markdown if request.path.ends_with?(".md")

    structured_data = {
      "@context"    => "https://schema.org",
      "@type"       => "Blog",
      "name"        => "Amber Framework blog",
      "description" => "Release notes, engineering stories, and practical Crystal guidance from Amber Framework.",
      "url"         => "#{SITE_URL}/blog",
      "blogPost"    => @posts.map { |post| blog_post_schema(post) },
    }.to_json
    @image = @posts.first["image"].to_s
    render("index.ecr")
  end

  def show
    return show_json if request.path.ends_with?(".json")
    return show_markdown if request.path.ends_with?(".md")

    filepath = requested_filepath
    post = find_post(filepath)
    if post
      @image = post["image"].to_s
      structured_data = blog_post_schema(post).to_json
      render("show.ecr")
    else
      raise Amber::Exceptions::RouteNotFound.new(request)
    end
  end

  def index_json
    response.content_type = "application/json; charset=utf-8"
    {
      title:    "Amber Framework blog",
      url:      "#{SITE_URL}/blog",
      feed_url: "#{SITE_URL}/blog/feed.xml",
      posts:    @posts.map { |post| public_post(post) },
    }.to_json
  end

  def index_markdown
    response.content_type = "text/markdown; charset=utf-8"
    String.build do |markdown|
      markdown << "# Amber Framework blog\n\n"
      markdown << "Release notes, engineering stories, and practical Crystal guidance.\n\n"
      markdown << "RSS: #{SITE_URL}/blog/feed.xml\n\n"
      @posts.each do |post|
        markdown << "## [#{post["title"]}](#{SITE_URL}#{post_path(post)})\n\n"
        markdown << "#{post["date"]} · #{post["category"]? || "Framework"} · #{post["author"]}\n\n"
        markdown << "#{post["summary"]? || "An update from the Amber Framework community."}\n\n"
      end
    end
  end

  def show_json
    post = find_post(requested_filepath)
    return not_found unless post

    response.content_type = "application/json; charset=utf-8"
    public_post(post).merge({content_markdown: File.read(requested_filepath)}).to_json
  end

  def show_markdown
    post = find_post(requested_filepath)
    return not_found unless post

    response.content_type = "text/markdown; charset=utf-8"
    response.headers["Content-Disposition"] = "inline"
    File.read(requested_filepath)
  end

  def feed
    response.content_type = "application/rss+xml; charset=utf-8"
    response.headers["Cache-Control"] = "public, max-age=900"

    String.build do |xml|
      xml << %(<?xml version="1.0" encoding="UTF-8"?>\n)
      xml << %(<rss version="2.0"><channel>\n)
      xml << "<title>Amber Framework blog</title>\n"
      xml << "<link>#{SITE_URL}/blog</link>\n"
      xml << "<description>Release notes, engineering stories, and practical Crystal guidance.</description>\n"
      xml << "<language>en-us</language>\n"
      @posts.each do |post|
        url = "#{SITE_URL}#{post_path(post)}"
        xml << "<item>\n"
        xml << "<title>#{HTML.escape(post["title"].to_s)}</title>\n"
        xml << "<link>#{url}</link>\n"
        xml << "<guid isPermaLink=\"true\">#{url}</guid>\n"
        xml << "<pubDate>#{post_time(post).to_rfc2822}</pubDate>\n"
        xml << "<category>#{HTML.escape((post["category"]? || "Framework").to_s)}</category>\n"
        xml << "<description>#{HTML.escape((post["summary"]? || "An update from the Amber Framework community.").to_s)}</description>\n"
        xml << "</item>\n"
      end
      xml << "</channel></rss>\n"
    end
  end

  def post_path(post) : String
    "/#{post["file"].to_s.sub(/\.md$/, "")}"
  end

  def post_iso_date(post) : String
    post_time(post).to_s("%F")
  end

  private def requested_filepath : String
    normalized_path = request.path.sub(/\.(?:md|json)$/, "").lstrip('/')
    "#{normalized_path}.md"
  end

  private def find_post(filepath : String)
    @posts.find { |item| item["file"].to_s == filepath }
  end

  private def post_time(post) : Time
    parts = post["file"].to_s.split("/")
    Time.utc(parts[1].to_i, parts[2].to_i, parts[3].to_i)
  end

  private def public_post(post)
    {
      title:        post["title"].to_s,
      summary:      (post["summary"]? || "An update from the Amber Framework community.").to_s,
      date:         post_iso_date(post),
      category:     (post["category"]? || "Framework").to_s,
      author:       post["author"].to_s,
      url:          "#{SITE_URL}#{post_path(post)}",
      markdown_url: "#{SITE_URL}#{post_path(post)}.md",
      json_url:     "#{SITE_URL}#{post_path(post)}.json",
      image_url:    "#{SITE_URL}#{post["image"]}",
    }
  end

  private def blog_post_schema(post)
    {
      "@type"         => "BlogPosting",
      "headline"      => post["title"].to_s,
      "description"   => (post["summary"]? || "An update from the Amber Framework community.").to_s,
      "datePublished" => post_iso_date(post),
      "author"        => {"@type" => "Person", "name" => post["author"].to_s},
      "url"           => "#{SITE_URL}#{post_path(post)}",
      "image"         => "#{SITE_URL}#{post["image"]}",
    }
  end

  private def not_found
    response.status_code = 404
    {error: "Post not found"}.to_json
  end
end

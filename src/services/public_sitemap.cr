require "html"
require "yaml"

# Lists every public HTML page the site serves, for search engines.
#
# The list is computed from the same sources the pages render from: the
# SiteContent registry, blog/posts.yml, and the versioned docs folders. A new
# docs page, blog post, or registered site page appears without a hand edit.
module PublicSitemap
  extend self

  ORIGIN          = "https://amberframework.org"
  XML_NAMESPACE   = "http://www.sitemaps.org/schemas/sitemap/0.9"
  BLOG_POSTS_PATH = "blog/posts.yml"

  # Pages rendered outside the SiteContent registry. Redirecting routes
  # (/docs, /docs/latest, legacy paths) stay out: a sitemap lists final URLs.
  LIST_OF_STANDALONE_PAGE_PATHS = {"/blog", "/pioneers", "/roadmap", "/research", "/release-tracker"}

  # One `<url>` element. `last_modified` is nil when the source has no
  # trustworthy edit date, and the element then carries no `<lastmod>`.
  record Entry, location : String, last_modified : Time? = nil

  # The only blog/posts.yml field the sitemap needs; the post's publication
  # date is read from its dated file path, as BlogController does.
  private struct BlogPostListing
    include YAML::Serializable

    getter file : String
  end

  # Returns one entry per public page, without duplicate locations.
  def list_of_entries : Array(Entry)
    list_of_blog_entries = blog_entries
    entries = site_page_entries(newest_post_date: list_of_blog_entries.compact_map(&.last_modified).max?)
    entries.concat(list_of_blog_entries)
    entries.concat(documentation_entries)
    entries.uniq(&.location)
  end

  # Renders entries as a sitemaps.org `urlset` document. Written with
  # String.build like the RSS feed; HTML.escape covers the five characters XML
  # reserves, so no XML library is linked for this.
  def to_xml(entries : Array(Entry)) : String
    String.build do |xml|
      xml << %(<?xml version="1.0" encoding="UTF-8"?>\n)
      xml << %(<urlset xmlns="#{XML_NAMESPACE}">\n)
      entries.each do |entry|
        xml << "  <url>\n"
        xml << "    <loc>" << HTML.escape(entry.location) << "</loc>\n"
        if last_modified = entry.last_modified
          xml << "    <lastmod>" << last_modified.to_s("%F") << "</lastmod>\n"
        end
        xml << "  </url>\n"
      end
      xml << "</urlset>\n"
    end
  end

  private def site_page_entries(newest_post_date : Time?) : Array(Entry)
    entries = SiteContent::PAGES.keys.map { |slug| Entry.new("#{ORIGIN}#{SiteContent.canonical_path(slug)}") }
    LIST_OF_STANDALONE_PAGE_PATHS.each do |path|
      # The blog index changes when a post is published.
      last_modified = path == "/blog" ? newest_post_date : nil
      entries << Entry.new("#{ORIGIN}#{path}", last_modified)
    end
    entries
  end

  private def blog_entries : Array(Entry)
    YAML.parse_all(File.read(BLOG_POSTS_PATH)).map do |document|
      post_file = BlogPostListing.from_yaml(document.to_yaml).file
      Entry.new("#{ORIGIN}/#{post_file.sub(/\.md\z/, "")}", publication_date(post_file))
    end
  end

  # blog/2026/08/13/slug.md was published on 2026-08-13.
  private def publication_date(post_file : String) : Time?
    if date_parts = post_file.match(/\Ablog\/(\d{4})\/(\d{2})\/(\d{2})\//)
      Time.utc(date_parts[1].to_i, date_parts[2].to_i, date_parts[3].to_i)
    end
  end

  # Every page of every docs version that is not archived. Inherited pages
  # render under each version that inherits them, so each version lists them.
  private def documentation_entries : Array(Entry)
    DocVersionConfig.all.reject(&.archived?).flat_map do |version|
      DocsScanner.scan_version(version.id).map do |page|
        Entry.new("#{ORIGIN}/docs/#{page.url_path}", page.last_updated)
      end
    end
  end
end

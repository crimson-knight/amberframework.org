require "../spec_helper"

private def sitemap_locations : Array(String)
  PublicSitemap.list_of_entries.map(&.location)
end

describe PublicSitemap do
  before_each do
    DocsScanner.clear_cache
  end

  describe ".list_of_entries" do
    it "lists every page of every docs version that is not archived" do
      locations = sitemap_locations

      DocVersionConfig.all.reject(&.archived?).each do |version|
        pages = DocsScanner.scan_version(version.id)
        pages.should_not be_empty
        pages.each do |page|
          locations.should contain("https://amberframework.org/docs/#{page.url_path}")
        end
      end
      locations.should contain("https://amberframework.org/docs/v2")
      locations.should contain("https://amberframework.org/docs/v2/getting-started/installation")
    end

    it "leaves archived docs versions and redirecting routes out" do
      locations = sitemap_locations

      locations.none?(&.starts_with?("https://amberframework.org/docs/v1.4.1")).should be_true
      locations.should_not contain("https://amberframework.org/docs")
      locations.should_not contain("https://amberframework.org/docs/latest")
    end

    it "lists every blog post with its publication date as lastmod" do
      entry = PublicSitemap.list_of_entries.find(&.location.==("https://amberframework.org/blog/2026/08/13/amber-v2-router-on-a-four-dollar-droplet")).not_nil!
      entry.last_modified.should eq(Time.utc(2026, 8, 13))

      post_count = YAML.parse_all(File.read("blog/posts.yml")).size
      sitemap_locations.count(&.matches?(/\/blog\/\d{4}\/\d{2}\/\d{2}\//)).should eq(post_count)
    end

    it "dates the blog index by its newest post" do
      blog_index = PublicSitemap.list_of_entries.find(&.location.==("https://amberframework.org/blog")).not_nil!
      newest_post_date = PublicSitemap.list_of_entries.select(&.location.includes?("/blog/")).compact_map(&.last_modified).max
      blog_index.last_modified.should eq(newest_post_date)
    end

    it "lists every registered site page and standalone page" do
      locations = sitemap_locations

      SiteContent::PAGES.each_key do |slug|
        locations.should contain("https://amberframework.org#{SiteContent.canonical_path(slug)}")
      end
      PublicSitemap::LIST_OF_STANDALONE_PAGE_PATHS.each do |path|
        locations.should contain("https://amberframework.org#{path}")
      end
      locations.should contain("https://amberframework.org/")
      locations.should contain("https://amberframework.org/performance")
      locations.should contain("https://amberframework.org/characters/grant")
    end

    it "uses absolute https locations without duplicates" do
      locations = sitemap_locations

      locations.all?(&.starts_with?("https://amberframework.org/")).should be_true
      locations.uniq.size.should eq(locations.size)
    end
  end

  describe ".to_xml" do
    it "renders an escaped urlset with lastmod only where a date is known" do
      entries = [
        PublicSitemap::Entry.new("https://amberframework.org/a?b=1&c=2", Time.utc(2026, 11, 7)),
        PublicSitemap::Entry.new("https://amberframework.org/undated"),
      ]

      PublicSitemap.to_xml(entries).should eq(<<-XML)
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>https://amberframework.org/a?b=1&amp;c=2</loc>
          <lastmod>2026-11-07</lastmod>
        </url>
        <url>
          <loc>https://amberframework.org/undated</loc>
        </url>
      </urlset>

      XML
    end

    it "renders the site's own entries as one sitemap" do
      xml = PublicSitemap.to_xml(PublicSitemap.list_of_entries)

      xml.should start_with(%(<?xml version="1.0" encoding="UTF-8"?>\n<urlset ))
      xml.should end_with("</urlset>\n")
      xml.scan(/<url>/).size.should eq(PublicSitemap.list_of_entries.size)
      xml.scan(/<\/url>/).size.should eq(PublicSitemap.list_of_entries.size)
      # A single sitemap holds up to 50,000 URLs; past that the site needs an index.
      PublicSitemap.list_of_entries.size.should be < 50_000
    end
  end
end

describe DocPage do
  it "reads an optional last_updated date from front matter" do
    File.tempfile("dated", ".md") do |file|
      file.print("---\ntitle: Dated\nlast_updated: 2026-11-07\n---\n\n# Dated\n")
    end.tap do |file|
      page = DocPage.from_file(file.path).not_nil!
      page.last_updated.should eq(Time.utc(2026, 11, 7))
      file.delete
    end
  end

  it "leaves last_updated empty when front matter has no date" do
    DocPage.from_file("docs/v2/index.md").not_nil!.last_updated.should be_nil
  end
end

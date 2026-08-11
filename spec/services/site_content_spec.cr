require "../spec_helper"

describe SiteContent do
  it "publishes Markdown and JSON for every registered public page" do
    SiteContent::PAGES.each_key do |slug|
      canonical_path = slug == "index" ? "/" : (slug.in?({"amber", "grant", "gemma"}) ? "/characters/#{slug}" : "/#{slug}")

      markdown = SiteContent.markdown(slug, canonical_path).not_nil!
      markdown.should start_with("# ")
      markdown.should contain("Canonical page: https://amberframework.org#{canonical_path}")

      json = JSON.parse(SiteContent.json(slug, canonical_path).not_nil!)
      json["canonical_url"].as_s.should eq("https://amberframework.org#{canonical_path}")
      json["sections"].as_a.should_not be_empty
    end
  end

  it "does not invent content for an unknown page" do
    SiteContent.markdown("missing", "/missing").should be_nil
    SiteContent.json("missing", "/missing").should be_nil
  end
end

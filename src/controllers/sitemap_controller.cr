require "../services/public_sitemap"

# Serves the sitemap computed from the site's own content, so it never drifts
# from the pages that actually exist.
class SitemapController < ApplicationController
  def show : String
    response.content_type = "application/xml; charset=utf-8"
    response.headers["Cache-Control"] = "public, max-age=3600"
    PublicSitemap.to_xml(PublicSitemap.list_of_entries)
  end
end

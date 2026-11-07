module ApplicationHelper
  LAYOUT = "application.ecr"
  @title = "Amber Framework — Web development, crystal clear"
  @meta = "Build fast, typed web applications with Amber 2 and the Crystal language."
  @image = "characters/amber-hero-original-studio.webp"
  # Open Graph type; a blog post sets "article" and its ISO publication date.
  @og_type = "website"
  @published_on : String? = nil
  @development : Bool? = Amber.env.development?

  @latest_amber_version = "2.0.0-beta.6"
  @latest_amber_release_date = "November 1, 2026"
end

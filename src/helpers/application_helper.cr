module ApplicationHelper
  LAYOUT = "application.ecr"
  @title = "Amber Framework — Web development, crystal clear"
  @meta = "Build fast, typed web applications with Amber 2 and the Crystal language."
  @image = "characters/amber-hero-original-studio.webp"
  @development : Bool? = Amber.env.development?

  @latest_amber_version = "2.0.0-beta.4"
  @latest_amber_release_date = "July 31, 2026"
end

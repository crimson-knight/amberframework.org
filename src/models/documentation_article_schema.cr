require "json"

# The schema.org TechArticle that describes one documentation page as JSON-LD,
# so search engines can read its headline, summary, version and address.
struct DocumentationArticleSchema
  include JSON::Serializable

  @[JSON::Field(key: "@context")]
  getter schema_context : String = "https://schema.org"

  @[JSON::Field(key: "@type")]
  getter schema_type : String = "TechArticle"

  getter headline : String
  getter description : String
  getter url : String

  @[JSON::Field(key: "inLanguage")]
  getter language_code : String = "en-US"

  # The docs version label, e.g. "2.0 Web Beta".
  getter version : String

  # Omitted from the JSON when the page declares no `last_updated` date.
  @[JSON::Field(key: "dateModified")]
  getter date_modified : String?

  def initialize(@headline : String, @description : String, @url : String, @version : String, @date_modified : String? = nil)
  end

  # Returns JSON that is safe inside a `<script>` element: a "</" in page
  # text would otherwise end the element early.
  def to_script_json : String
    to_json.gsub("</", "<\\/")
  end
end

# Data structures for documentation pages

class DocPage
  include YAML::Serializable

  property title : String = "Untitled"
  property section : String = ""
  property order : Int32 = 100
  property description : String = ""
  property is_section : Bool = false

  # Runtime properties (not from YAML)
  @[YAML::Field(ignore: true)]
  property file_path : String = ""

  @[YAML::Field(ignore: true)]
  property url_path : String = ""

  @[YAML::Field(ignore: true)]
  property content : String = ""

  # Path relative to version folder (e.g., "guides/installation.md")
  # Used for inheritance checking between versions
  @[YAML::Field(ignore: true)]
  property relative_path : String = ""

  def initialize
  end

  # Load page from file with version context
  # version_folder is the folder name like "v1" or "v2-preview"
  def self.from_file(file_path : String, version_folder : String? = nil) : DocPage?
    return nil unless File.exists?(file_path)

    raw_content = File.read(file_path)
    frontmatter, body = parse_frontmatter(raw_content)

    begin
      page = DocPage.from_yaml(frontmatter)
      page.file_path = file_path
      page.url_path = file_to_url(file_path, version_folder)
      page.relative_path = file_to_relative(file_path, version_folder)
      page.content = body
      page
    rescue ex : YAML::ParseException
      # Return a basic page if frontmatter is invalid
      page = DocPage.new
      page.file_path = file_path
      page.url_path = file_to_url(file_path, version_folder)
      page.relative_path = file_to_relative(file_path, version_folder)
      page.content = raw_content
      page
    end
  end

  private def self.parse_frontmatter(content : String) : {String, String}
    if content.starts_with?("---")
      # Split on frontmatter delimiters
      lines = content.split("\n")
      end_index = 0
      found_start = false

      lines.each_with_index do |line, i|
        if line.strip == "---"
          if !found_start
            found_start = true
          else
            end_index = i
            break
          end
        end
      end

      if end_index > 0
        frontmatter = lines[1...end_index].join("\n")
        body = lines[(end_index + 1)..].join("\n").strip
        {frontmatter, body}
      else
        {"title: Untitled", content}
      end
    else
      {"title: Untitled", content}
    end
  end

  # Convert file path to URL path (includes version prefix)
  # e.g., "docs/v1/guides/installation.md" -> "v1/guides/installation"
  private def self.file_to_url(file_path : String, version_folder : String? = nil) : String
    path = file_path
      .sub(/^docs\//, "")  # Remove docs/ prefix
      .sub(/\.md$/, "")    # Remove .md extension
      .sub(/\/index$/, "") # /index becomes /

    # Handle root index
    if version_folder
      path = path.sub(/^#{Regex.escape(version_folder)}$/, version_folder)
    else
      path = path.sub(/^index$/, "")
    end

    path
  end

  # Convert file path to relative path within version folder
  # e.g., "docs/v1/guides/installation.md" -> "guides/installation.md"
  private def self.file_to_relative(file_path : String, version_folder : String?) : String
    path = file_path.sub(/^docs\//, "") # Remove docs/ prefix

    if version_folder
      path = path.sub(/^#{Regex.escape(version_folder)}\//, "") # Remove version prefix
    end

    path
  end
end

# Navigation item for sidebar tree
class NavItem
  property title : String
  property path : String
  property order : Int32
  property is_section : Bool
  property children : Array(NavItem)
  property badge : String?       # "New", "Updated", etc.
  property badge_class : String? # CSS class for badge

  def initialize(@title : String, @path : String, @order : Int32 = 100, @is_section : Bool = false)
    @children = [] of NavItem
    @badge = nil
    @badge_class = nil
  end

  def add_child(item : NavItem)
    @children << item
    @children.sort_by! { |c| c.order }
  end

  def set_badge(text : String?, css_class : String? = nil)
    @badge = text
    @badge_class = css_class
  end
end

# Status of a page in a specific version
enum PageVersionStatus
  Added     # Page first appears in this version
  Updated   # Line count increased from previous (>5 lines)
  Reduced   # Line count decreased from previous (>5 lines)
  Unchanged # Same line count as previous (within ±5 lines)
  Removed   # Page deleted via _deleted.yml
  Inherited # Inherited unchanged from parent version
end

# Represents a page's state in a single version
struct PageVersionEntry
  property version_id : String
  property version_name : String
  property line_count : Int32
  property status : PageVersionStatus
  property file_exists : Bool
  property is_inherited : Bool
  property line_delta : Int32?

  def initialize(
    @version_id : String,
    @version_name : String,
    @line_count : Int32,
    @status : PageVersionStatus,
    @file_exists : Bool,
    @is_inherited : Bool,
    @line_delta : Int32? = nil,
  )
  end

  # Check if page is available in this version (not removed)
  def available? : Bool
    !status.removed?
  end

  # Get CSS class for change indicator
  def change_indicator_class : String?
    case status
    when .updated?
      "added"
    when .reduced?
      "reduced"
    else
      nil
    end
  end
end

# Complete version history for a single page
struct PageVersionHistory
  property relative_path : String
  property entries : Array(PageVersionEntry)

  def initialize(@relative_path : String, @entries : Array(PageVersionEntry) = [] of PageVersionEntry)
  end

  # Get entry for a specific version
  def for_version(version_id : String) : PageVersionEntry?
    entries.find { |e| e.version_id == version_id }
  end

  # Get all versions where page exists (not removed)
  def available_versions : Array(PageVersionEntry)
    entries.select { |e| e.available? }
  end

  # Check if page has significant changes across versions
  def has_changes? : Bool
    entries.any? { |e| e.status.updated? || e.status.reduced? || e.status.added? }
  end
end

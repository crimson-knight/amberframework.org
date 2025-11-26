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

  def initialize
  end

  def self.from_file(file_path : String) : DocPage?
    return nil unless File.exists?(file_path)

    raw_content = File.read(file_path)
    frontmatter, body = parse_frontmatter(raw_content)

    begin
      page = DocPage.from_yaml(frontmatter)
      page.file_path = file_path
      page.url_path = file_to_url(file_path)
      page.content = body
      page
    rescue ex : YAML::ParseException
      # Return a basic page if frontmatter is invalid
      page = DocPage.new
      page.file_path = file_path
      page.url_path = file_to_url(file_path)
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

  private def self.file_to_url(file_path : String) : String
    file_path
      .sub(/^docs\//, "")      # Remove docs/ prefix
      .sub(/\.md$/, "")        # Remove .md extension
      .sub(/\/index$/, "")     # /index becomes /
      .sub(/^index$/, "")      # Root index becomes empty
  end
end

# Navigation item for sidebar tree
class NavItem
  property title : String
  property path : String
  property order : Int32
  property is_section : Bool
  property children : Array(NavItem)

  def initialize(@title : String, @path : String, @order : Int32 = 100, @is_section : Bool = false)
    @children = [] of NavItem
  end

  def add_child(item : NavItem)
    @children << item
    @children.sort_by! { |c| c.order }
  end
end

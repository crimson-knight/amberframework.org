# Model representing a documentation version
#
# Versions form an inheritance chain - when a page doesn't exist in a version,
# the system falls back to the inherited version. This allows new versions to
# only contain changed documentation.

class DocVersion
  include YAML::Serializable

  property id : String
  property name : String
  property label : String
  property amber_versions : String = ""
  property status : String = "stable"
  property inherits_from : String? = nil
  property release_date : String? = nil
  property description : String = ""

  def stable?
    status == "stable"
  end

  def preview?
    status == "preview"
  end

  def deprecated?
    status == "deprecated"
  end

  def archived?
    status == "archived"
  end

  # CSS class for status badge
  def status_class : String
    case status
    when "stable"     then "badge-success"
    when "preview"    then "badge-warning"
    when "deprecated" then "badge-secondary"
    when "archived"   then "badge-dark"
    else                   "badge-info"
    end
  end

  # URL path prefix for this version
  def url_prefix : String
    "/docs/#{id}"
  end

  # Folder path for this version's docs
  def folder_path : String
    "docs/#{id}"
  end
end

# Configuration loader for documentation versions
class DocVersionConfig
  include YAML::Serializable

  property default_version : String
  property versions : Array(DocVersion)

  # Class-level cache
  @@instance : DocVersionConfig? = nil

  def self.load : DocVersionConfig
    @@instance ||= begin
      config_path = "docs/versions.yml"
      if File.exists?(config_path)
        DocVersionConfig.from_yaml(File.read(config_path))
      else
        # Default config if file doesn't exist
        DocVersionConfig.from_yaml(%(
          default_version: v1
          versions:
            - id: v1
              name: "1.x"
              label: "1.x"
              status: stable
        ))
      end
    end
  end

  def self.reload
    @@instance = nil
    load
  end

  # Get all versions
  def self.all : Array(DocVersion)
    load.versions
  end

  # Get default version
  def self.default : DocVersion
    config = load
    find(config.default_version) || load.versions.first
  end

  # Find version by id
  def self.find(id : String) : DocVersion?
    load.versions.find { |v| v.id == id }
  end

  # Get stable versions
  def self.stable : Array(DocVersion)
    load.versions.select(&.stable?)
  end

  # Get the inheritance chain for a version (including itself)
  # Returns versions in order from most specific to most general
  def self.inheritance_chain(version_id : String) : Array(DocVersion)
    chain = [] of DocVersion
    current_id : String? = version_id

    while current_id
      if version = find(current_id)
        chain << version
        current_id = version.inherits_from
      else
        break
      end
    end

    chain
  end

  # Check if a version id is valid
  def self.valid?(id : String) : Bool
    !find(id).nil?
  end
end

# Represents a page with version context
# Wraps DocPage with additional version-specific information
class VersionedDocPage
  property page : DocPage
  property version : DocVersion
  property source_version : DocVersion  # The version where file actually exists
  property is_inherited : Bool          # True if page comes from parent version

  def initialize(@page : DocPage, @version : DocVersion, @source_version : DocVersion)
    @is_inherited = version.id != source_version.id
  end

  # Is this page new in this version? (exists only here, not in parent)
  def new_in_version? : Bool
    return false if is_inherited
    return false unless parent_version = version.inherits_from

    # Check if page exists in parent version
    parent_chain = DocVersionConfig.inheritance_chain(parent_version)
    parent_chain.none? do |pv|
      File.exists?(File.join(pv.folder_path, page.relative_path))
    end
  end

  # Is this page changed in this version? (exists here AND in parent)
  def changed_in_version? : Bool
    return false if is_inherited
    return false unless parent_version = version.inherits_from

    # Check if page also exists in parent version
    parent_chain = DocVersionConfig.inheritance_chain(parent_version)
    parent_chain.any? do |pv|
      File.exists?(File.join(pv.folder_path, page.relative_path))
    end
  end

  # Badge text for UI
  def version_badge : String?
    if new_in_version?
      "New"
    elsif changed_in_version?
      "Updated"
    else
      nil
    end
  end

  # Badge CSS class
  def version_badge_class : String
    if new_in_version?
      "badge-success"
    elsif changed_in_version?
      "badge-info"
    else
      ""
    end
  end

  # Delegate common methods to page
  delegate title, to: page
  delegate content, to: page
  delegate description, to: page
  delegate url_path, to: page
  delegate section, to: page
  delegate order, to: page
  delegate is_section, to: page
  delegate file_path, to: page
end

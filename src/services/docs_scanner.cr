# Service to auto-discover and scan documentation markdown files
# Supports versioned documentation with inheritance and deletions

module DocsScanner
  extend self

  DOCS_ROOT        = "docs"
  DELETED_FILENAME = "_deleted.yml"

  # Cache structure: version_id => pages
  @@version_pages : Hash(String, Array(DocPage)) = {} of String => Array(DocPage)
  @@version_nav_trees : Hash(String, Array(NavItem)) = {} of String => Array(NavItem)
  @@version_deleted_paths : Hash(String, Set(String)) = {} of String => Set(String)

  # Cache for version history tracking
  @@page_histories : Hash(String, PageVersionHistory) = {} of String => PageVersionHistory
  @@version_line_counts : Hash(String, Hash(String, Int32)) = {} of String => Hash(String, Int32)

  # Minimum line difference threshold to show change indicator
  LINE_CHANGE_THRESHOLD = 5

  # Scan all markdown files for a specific version
  # Includes inherited pages from parent versions
  # Respects _deleted.yml files that mark pages as deleted from this version
  def scan_version(version_id : String) : Array(DocPage)
    return @@version_pages[version_id] if @@version_pages.has_key?(version_id)

    version = DocVersionConfig.find(version_id)
    return [] of DocPage unless version

    # Get inheritance chain (most specific first)
    chain = DocVersionConfig.inheritance_chain(version_id)

    # Build merged page list: start with base, overlay with more specific
    # We need to track relative paths to handle overrides correctly
    pages_by_relative = {} of String => DocPage

    # Track accumulated deletions through the chain
    deleted_paths = Set(String).new

    # Process chain in reverse (base first, then overlays)
    chain.reverse.each do |v|
      # First, add pages from this version
      scan_folder(v.folder_path, v.id).each do |page|
        # Only add if not already marked as deleted
        unless deleted_paths.includes?(page.relative_path)
          pages_by_relative[page.relative_path] = page
        end
      end

      # Then process deletions for this version
      # Deletions cascade - once deleted, stays deleted in child versions
      version_deletions = load_deleted_paths(v.id)
      version_deletions.each do |deleted_path|
        deleted_paths.add(deleted_path)
        pages_by_relative.delete(deleted_path)
      end
    end

    # Store accumulated deletions for this version (used by badges)
    @@version_deleted_paths[version_id] = deleted_paths

    # Convert to array and update URL paths for this version
    pages = pages_by_relative.values.map do |page|
      adjusted_page = page.dup

      # Extract the original version folder from the page's url_path
      original_version = page.url_path.split("/").first

      # Calculate path without the original version prefix
      url_without_version = if page.url_path == original_version
                              # This is the root index page (e.g., "v1" -> "")
                              ""
                            else
                              # Strip version prefix with slash (e.g., "v1/guides" -> "guides")
                              page.url_path.sub(/^#{Regex.escape(original_version)}\//, "")
                            end

      # Build new URL path with target version prefix
      adjusted_page.url_path = if url_without_version.empty?
                                 version_id
                               else
                                 "#{version_id}/#{url_without_version}"
                               end

      adjusted_page
    end

    # Sort by section and order
    pages.sort_by! { |p| {p.section, p.order, p.title} }

    @@version_pages[version_id] = pages
    pages
  end

  # Scan just the files in a specific folder (no inheritance)
  def scan_folder(folder_path : String, version_id : String) : Array(DocPage)
    pages = [] of DocPage

    return pages unless Dir.exists?(folder_path)

    Dir.glob("#{folder_path}/**/*.md").each do |file_path|
      # Skip SUMMARY.md, versions.yml
      next if file_path.ends_with?("SUMMARY.md")
      next if file_path.ends_with?("versions.yml")

      page = DocPage.from_file(file_path, version_id)
      pages << page if page
    end

    pages
  end

  # Get pages that exist ONLY in this version (not inherited)
  def scan_version_only(version_id : String) : Array(DocPage)
    version = DocVersionConfig.find(version_id)
    return [] of DocPage unless version

    scan_folder(version.folder_path, version_id)
  end

  # Build navigation tree for a version
  def build_nav_tree_for_version(version_id : String) : Array(NavItem)
    return @@version_nav_trees[version_id] if @@version_nav_trees.has_key?(version_id)

    pages = scan_version(version_id)
    version = DocVersionConfig.find(version_id)
    return [] of NavItem unless version

    # For base versions (no inheritance), don't show any badges
    # Everything would be "new" which is meaningless
    own_relative_paths = Set(String).new
    parent_relative_paths = Set(String).new

    if parent_id = version.inherits_from
      # Only calculate badges for versions with inheritance
      own_pages = scan_version_only(version_id)
      own_relative_paths = own_pages.map(&.relative_path).to_set

      parent_pages = scan_version_only(parent_id)
      parent_relative_paths = parent_pages.map(&.relative_path).to_set
    end

    nav_tree = build_nav_tree(pages, version_id, own_relative_paths, parent_relative_paths)
    @@version_nav_trees[version_id] = nav_tree
    nav_tree
  end

  # Build navigation tree from pages
  private def build_nav_tree(
    pages : Array(DocPage),
    version_id : String,
    own_paths : Set(String),
    parent_paths : Set(String),
  ) : Array(NavItem)
    root_items = [] of NavItem
    section_map = {} of String => NavItem

    # First pass: create all section items and leaf items
    pages.each do |page|
      # Calculate badge for this page
      badge, badge_class = calculate_badge(page.relative_path, own_paths, parent_paths)

      if page.section.empty?
        # Root level item
        item = NavItem.new(page.title, page.url_path, page.order, page.is_section)
        item.set_badge(badge, badge_class)

        if page.is_section
          section_map[page.url_path] = item
        end
        root_items << item
      else
        # Need to ensure parent sections exist
        ensure_section_exists(page.section, section_map, root_items, pages, version_id)

        # Add this item to its parent section
        parent_key = find_section_key(page.section, section_map, version_id)
        if parent_key && (parent = section_map[parent_key]?)
          item = NavItem.new(page.title, page.url_path, page.order, page.is_section)
          item.set_badge(badge, badge_class)

          if page.is_section
            section_map[page.url_path] = item
          end
          parent.add_child(item)
        end
      end
    end

    # Sort root items
    root_items.sort_by! { |i| i.order }
    root_items
  end

  private def calculate_badge(relative_path : String, own_paths : Set(String), parent_paths : Set(String)) : {String?, String?}
    return {nil, nil} unless own_paths.includes?(relative_path)

    if parent_paths.includes?(relative_path)
      # Exists in both: Updated
      {"Updated", "badge-info"}
    else
      # Only in this version: New
      {"New", "badge-success"}
    end
  end

  # Load paths marked as deleted for a specific version
  # Reads from _deleted.yml in the version's folder
  # Returns empty set if file doesn't exist
  private def load_deleted_paths(version_id : String) : Set(String)
    version = DocVersionConfig.find(version_id)
    return Set(String).new unless version

    deleted_file = File.join(version.folder_path, DELETED_FILENAME)
    return Set(String).new unless File.exists?(deleted_file)

    begin
      yaml_content = YAML.parse(File.read(deleted_file))
      paths = Set(String).new

      # Handle array format: ["path1", "path2"]
      if yaml_content.as_a?
        yaml_content.as_a.each do |item|
          if path = item.as_s?
            # Normalize path: ensure no leading slash, handle various formats
            normalized = path.strip.lstrip('/')
            paths.add(normalized) unless normalized.empty?
          end
        end
      end

      paths
    rescue ex
      # Log error but don't crash - return empty set
      puts "Warning: Error parsing #{deleted_file}: #{ex.message}"
      Set(String).new
    end
  end

  private def find_section_key(section : String, section_map : Hash(String, NavItem), version_id : String) : String?
    # Try with version prefix
    versioned_path = "#{version_id}/#{section}"
    return versioned_path if section_map.has_key?(versioned_path)

    # Try without version prefix
    section_map.keys.find { |k| k.ends_with?("/#{section}") || k == section }
  end

  private def ensure_section_exists(
    section_path : String,
    section_map : Hash(String, NavItem),
    root_items : Array(NavItem),
    pages : Array(DocPage),
    version_id : String,
  )
    parts = section_path.split("/")
    current_path = version_id

    parts.each_with_index do |part, i|
      parent_path = current_path
      current_path = "#{current_path}/#{part}"

      unless section_map.has_key?(current_path)
        # Find the page for this section or create a placeholder
        section_page = pages.find { |p| p.url_path == current_path && p.is_section }
        title = section_page ? section_page.title : part.capitalize
        order = section_page ? section_page.order : 100

        item = NavItem.new(title, current_path, order, true)
        section_map[current_path] = item

        if parent_path == version_id
          root_items << item
        elsif parent = section_map[parent_path]?
          parent.add_child(item)
        end
      end
    end
  end

  # Find a page by URL path within a version
  def find_page(version_id : String, url_path : String) : DocPage?
    pages = scan_version(version_id)
    normalized = url_path.strip("/")

    # Build full path with version prefix
    full_path = if normalized.empty? || normalized == version_id
                  version_id
                elsif normalized.starts_with?("#{version_id}/")
                  normalized
                else
                  "#{version_id}/#{normalized}"
                end

    # Try exact match first
    pages.find { |p| p.url_path == full_path } ||
      # Try with /index suffix for directory pages
      pages.find { |p| p.url_path == "#{full_path}/index" }
  end

  # Get breadcrumbs for a path within a version
  def breadcrumbs(version_id : String, url_path : String) : Array(NamedTuple(title: String, path: String))
    pages = scan_version(version_id)
    crumbs = [] of NamedTuple(title: String, path: String)

    # Remove version prefix from path for processing
    path_without_version = url_path.sub(/^#{Regex.escape(version_id)}\//, "")
    parts = path_without_version.split("/").reject(&.empty?)

    current_path = version_id

    parts.each do |part|
      current_path = "#{current_path}/#{part}"
      if page = pages.find { |p| p.url_path == current_path }
        crumbs << {title: page.title, path: current_path}
      end
    end

    crumbs
  end

  # Get previous and next pages for navigation within a version
  def prev_next(version_id : String, url_path : String) : {DocPage?, DocPage?}
    pages = scan_version(version_id)

    # Get flat list of pages in navigation order, excluding root index
    flat_pages = pages.reject { |p| p.url_path == version_id }.sort_by { |p| {p.section, p.order} }

    # Build full path if needed
    full_path = if url_path.starts_with?("#{version_id}/") || url_path == version_id
                  url_path
                else
                  "#{version_id}/#{url_path}"
                end

    current_index = flat_pages.index { |p| p.url_path == full_path }

    return {nil, nil} unless current_index

    prev_page = current_index > 0 ? flat_pages[current_index - 1] : nil
    next_page = current_index < flat_pages.size - 1 ? flat_pages[current_index + 1] : nil

    {prev_page, next_page}
  end

  # Check which version a file belongs to (where it actually exists)
  def source_version(version_id : String, relative_path : String) : String?
    chain = DocVersionConfig.inheritance_chain(version_id)

    chain.each do |v|
      file_path = File.join(v.folder_path, relative_path)
      return v.id if File.exists?(file_path)
    end

    nil
  end

  # Get list of files that are new or changed in a version
  def changed_files(version_id : String) : Array(NamedTuple(path: String, status: String))
    version = DocVersionConfig.find(version_id)
    return [] of NamedTuple(path: String, status: String) unless version

    own_pages = scan_version_only(version_id)
    parent_paths = Set(String).new

    if parent_id = version.inherits_from
      parent_pages = scan_version_only(parent_id)
      parent_paths = parent_pages.map(&.relative_path).to_set
    end

    own_pages.map do |page|
      status = parent_paths.includes?(page.relative_path) ? "updated" : "new"
      {path: page.relative_path, status: status}
    end
  end

  # Clear all caches (useful for development/testing)
  def clear_cache
    @@version_pages.clear
    @@version_nav_trees.clear
    @@version_deleted_paths.clear
    @@page_histories.clear
    @@version_line_counts.clear
  end

  # ===========================================
  # Version History Tracking
  # ===========================================

  # Get the complete version history for a page by its relative path
  def get_page_version_history(relative_path : String) : PageVersionHistory
    return @@page_histories[relative_path] if @@page_histories.has_key?(relative_path)

    history = compute_page_version_history(relative_path)
    @@page_histories[relative_path] = history
    history
  end

  # Get version history for a page by its URL path
  def get_history_for_page(version_id : String, url_path : String) : PageVersionHistory?
    page = find_page(version_id, url_path)
    return nil unless page

    get_page_version_history(page.relative_path)
  end

  # Compute the complete version history for a page
  private def compute_page_version_history(relative_path : String) : PageVersionHistory
    versions = DocVersionConfig.all

    # Filter to only latest patch per minor version
    display_versions = filter_to_latest_patches(versions)

    entries = [] of PageVersionEntry
    previous_line_count : Int32? = nil

    # Process versions in chronological order (oldest first)
    display_versions.each do |version|
      entry = compute_version_entry(relative_path, version, previous_line_count)
      entries << entry

      # Update previous line count for next iteration (unless removed)
      unless entry.status.removed?
        previous_line_count = entry.line_count if entry.line_count > 0
      end
    end

    PageVersionHistory.new(relative_path, entries)
  end

  # Compute a single version entry for a page
  private def compute_version_entry(
    relative_path : String,
    version : DocVersion,
    previous_line_count : Int32?,
  ) : PageVersionEntry
    # Check if page is deleted in this version
    deleted_paths = load_deleted_paths(version.id)
    if deleted_paths.includes?(relative_path)
      return PageVersionEntry.new(
        version_id: version.id,
        version_name: version.name,
        line_count: 0,
        status: PageVersionStatus::Removed,
        file_exists: false,
        is_inherited: false,
        line_delta: previous_line_count ? -previous_line_count : nil
      )
    end

    # Check if file exists directly in this version's folder
    file_path = File.join(version.folder_path, relative_path)
    file_exists = File.exists?(file_path)

    # Get line count (from this version or inherited)
    line_count = get_line_count_for_page(relative_path, version.id)

    # If page doesn't exist at all in this version's tree
    if line_count == 0 && !file_exists
      source_ver = source_version(version.id, relative_path)
      if source_ver.nil?
        return PageVersionEntry.new(
          version_id: version.id,
          version_name: version.name,
          line_count: 0,
          status: PageVersionStatus::Removed,
          file_exists: false,
          is_inherited: false,
          line_delta: nil
        )
      end
    end

    # Determine if inherited (exists through parent, not directly in this version)
    is_inherited = !file_exists && line_count > 0

    # Determine status
    status = determine_status(line_count, previous_line_count, file_exists, is_inherited)

    # Calculate line delta
    line_delta = previous_line_count ? (line_count - previous_line_count) : nil

    PageVersionEntry.new(
      version_id: version.id,
      version_name: version.name,
      line_count: line_count,
      status: status,
      file_exists: file_exists,
      is_inherited: is_inherited,
      line_delta: line_delta
    )
  end

  # Determine the status of a page in a version
  private def determine_status(
    line_count : Int32,
    previous_line_count : Int32?,
    file_exists : Bool,
    is_inherited : Bool,
  ) : PageVersionStatus
    # First version for this page
    if previous_line_count.nil?
      return PageVersionStatus::Added
    end

    # Inherited without changes
    if is_inherited
      return PageVersionStatus::Inherited
    end

    # Compare line counts with threshold
    delta = line_count - previous_line_count

    if delta > LINE_CHANGE_THRESHOLD
      PageVersionStatus::Updated
    elsif delta < -LINE_CHANGE_THRESHOLD
      PageVersionStatus::Reduced
    else
      PageVersionStatus::Unchanged
    end
  end

  # Get line count for a page in a version (cached)
  private def get_line_count_for_page(relative_path : String, version_id : String) : Int32
    # Check cache first
    if counts = @@version_line_counts[version_id]?
      if count = counts[relative_path]?
        return count
      end
    end

    # Find the actual file through inheritance chain
    chain = DocVersionConfig.inheritance_chain(version_id)

    chain.each do |v|
      file_path = File.join(v.folder_path, relative_path)
      if File.exists?(file_path)
        count = count_lines(file_path)

        # Cache the result
        @@version_line_counts[version_id] ||= {} of String => Int32
        @@version_line_counts[version_id][relative_path] = count

        return count
      end
    end

    0 # Page doesn't exist
  end

  # Count non-empty content lines in a markdown file (excluding frontmatter)
  private def count_lines(file_path : String) : Int32
    return 0 unless File.exists?(file_path)

    content = File.read(file_path)

    # Remove YAML frontmatter
    body = if content.starts_with?("---")
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
               lines[(end_index + 1)..].join("\n")
             else
               content
             end
           else
             content
           end

    # Count non-empty lines
    body.lines.count { |line| !line.strip.empty? }
  end

  # Filter versions to only show latest patch per major.minor
  private def filter_to_latest_patches(versions : Array(DocVersion)) : Array(DocVersion)
    # Group by major.minor
    grouped = {} of String => Array(DocVersion)

    versions.each do |v|
      # Parse version: "1.4.1" -> major_minor = "1.4"
      parts = v.name.split(".")
      major_minor = if parts.size >= 2
                      "#{parts[0]}.#{parts[1]}"
                    else
                      v.name
                    end

      grouped[major_minor] ||= [] of DocVersion
      grouped[major_minor] << v
    end

    # Keep only the highest patch version in each group
    result = grouped.values.compact_map do |group|
      group.max_by { |v| parse_version_number(v.name) }
    end

    # Sort by version number (oldest first for timeline)
    result.sort_by { |v| parse_version_number(v.name) }
  end

  # Parse version string to tuple for comparison
  private def parse_version_number(name : String) : {Int32, Int32, Int32}
    parts = name.gsub(/[^0-9.]/, "").split(".")
    major = parts[0]?.try(&.to_i?) || 0
    minor = parts[1]?.try(&.to_i?) || 0
    patch = parts[2]?.try(&.to_i?) || 0
    {major, minor, patch}
  end

  # Get paths marked as deleted for a version (for display/debugging)
  def deleted_paths(version_id : String) : Set(String)
    # Ensure scan_version has been called to populate the cache
    scan_version(version_id)
    @@version_deleted_paths[version_id]? || Set(String).new
  end

  # Backward compatibility: scan_all returns default version pages
  def scan_all : Array(DocPage)
    scan_version(DocVersionConfig.default.id)
  end

  # Backward compatibility: build_nav_tree
  def build_nav_tree(pages : Array(DocPage)) : Array(NavItem)
    build_nav_tree_for_version(DocVersionConfig.default.id)
  end
end
